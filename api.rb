require 'dotenv/load'
require 'sinatra/base'
require 'sinatra/reloader'
require 'json'
require 'onix'
require 'bigdecimal'
require 'bigdecimal/util'

class OnixApi < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  # we're a dumb api
  get '/' do
    status 403
    'Bad request.'
  end

  # handle api request
  post '/api' do

    # rudimentary auth
    api_key = params.fetch :api_key, ''
    if api_key != ENV['ONIX_API_KEY']
      status 403
      return "Invalid api key."
    end

    # parse json input
    json = JSON.parse(request.body.read)

    # make sure we have some products
    if !json['onixData'].key?('products') or json['onixData']['products'].empty?
      status 403
      return 'Bad request.'
    end

    # construct xml filename
    if json['onixData']['products'].length == 1
      # single product
      xml_out_filename = "public/output/onix-%s.xml" % json['onixData']['products'][0]['productId']
    else
      xml_out_filename = "public/output/onix-multiple-%s.xml" % Time.now.getutc
    end

    # output xml file
    File.open(xml_out_filename, 'w') do |output|
      header = ONIX::Header.new
      header.from_company = json['onixData']['from']['company']
      header.from_person  = json['onixData']['from']['person']
      header.from_email  = json['onixData']['from']['email']
      header.sent_date = Time.now

      writer = ONIX::Writer.new(output, header)

      json['onixData']['products'].each do |json_product|
        product = ONIX::APAProduct.new

        product.notification_type = 3
        product.measurement_system = :imperial

        product.title = json_product['title']
        product.subtitle = json_product['subtitle']
        product.main_description = json_product['description']
        product.short_description = json_product['shortDescription']
        product.publication_date = Date.parse(json_product['publishDate'])
        product.on_sale_date = Date.parse(json_product['shipDate'])

        # Edition?
        if !json_product['edition'].nil? && !json_product['edition'].empty?
          product.edition_number = json_product['edition']
        end

        json_product['authors'].each do |author|
          product.add_contributor(author['nameReverse'], author['bio'], author['roleCode'])
        end

        if !json_product['width'].empty?
          product.width = json_product['width']
        end
        if !json_product['height'].empty?
          product.height = json_product['height']
        end
        if !json_product['thickness'].empty?
          product.thickness = json_product['thickness']
        end

        product.number_of_pages = json_product['pageCount'].to_i

        # images
        product.thumbnail_url = json_product['thumbnail']
        product.cover_url = json_product['coverUrl']
        product.cover_url_hq = json_product['coverUrlHq']

        # sample content
        # from list 38, MediaFileTypeCode
        # "03" => "Image: whole cover",
        # "04" => "Image: front cover",
        # "05" => "Image: whole cover, high quality",
        # "06" => "Image: front cover, high quality",
        # "07" => "Image: front cover thumbnail",
        # "08" => "Image: contributor(s)",
        # "17" => "Image: publisher logo",
        # "18" => "Image: imprint logo",
        # "23" => "Image: sample content",
        # "24" => "Image: back cover",
        # "25" => "Image: back cover, high quality",
        # "26" => "Image: back cover thumbnail",

        # from list 40, MediaFileLinkTypeCode
        # "01" => "URL",
        # "02" => "DOI",
        # "03" => "PURL",
        # "04" => "URN",
        # "05" => "FTP address",
        # "06" => "filename"

        # add all interiors as media files
        if !json_product['interiors'].nil? && !json_product['interiors'].empty?
          json_product['interiors'].each do |image|
            product.add_media_file(23, 1, image)
          end
        end

        # ? what is this
        product.proprietary_id = json_product['productId']
        # also unsure of this
        product.record_reference = json_product['productId']
        product.isbn13 = json_product['isbn13']

        product.imprint = json_product['imprint']
        product.publisher = json_product['publisher']
        product.publisher_website = json_product['url']

        # what's this?
        # product.sales_restriction_type = 0

        # Set sales rights
        product.add_sales_rights('02', '', 'WORLD')

        # this sets <website> type 12, "A webpage devoted to an individual work, and maintained by a third party (eg a fan site)"
        # product.supplier_website = json_product['supplier']['url']
        product.supplier_name = json_product['supplier']['name']
        product.supplier_phone = json_product['supplier']['phone']
        product.supplier_fax = json_product['supplier']['fax']
        product.supplier_email = json_product['supplier']['email']
        product.supply_country = 'US'

        # "06" => "Publisher’s sales expectation"
        # holding off on this as it makes no sense, originally was trying to populate "estimated sales" field from admin
        # product.add_supplier_own_coding('06', json_product['isbn13'])

        # subjects
        json_product['bisacCodes'].each_with_index do |bisac_code, i|
          if i == 0
            product.basic_main_subject = bisac_code
          end
          product.add_bisac_subject(bisac_code)
        end

        # codes for relatedProduct types
        # "23" => "Similar product",
        # "27" => "Electronic version available as",
        # "13" => "Epublication based on (print product)",

        # comp titles
        json_product['compTitles'].each do |isbn|
          product.add_related_product(23, isbn)
          # product.add_comp_title(isbn)
        end

        # ebook versions
        json_product['eBooks'].each do |isbn|
          product.add_related_product(13, isbn)
        end

        # audience_range
        if !json_product['audienceRange'].nil? && !json_product['audienceRange'].empty?
          product.audience_range = json_product['audienceRange']
        end

        # list 65
        # "10" => "Not yet available (needs expectedshipdate)",
        # "11" => "Awaiting stock (needs expectedshipdate)",
        # "20" => "Available",
        # "21" => "In stock",
        # "31" => "Out of stock",

        # if json_product['status'] == 'A' # "In Stock" status
        #   product.product_availability = 20
        # elsif json_product['status'] == 'P' # "Pre-Order" status
        #   product.product_availability = 10
        #   product.expected_ship_date = Date.parse(json_product['ship_date'])
        # elsif json_product['status'] == 'N' # "Out of Stock" status
        #   product.product_availability = 31
        # end

        # publishing_status
        if !json_product['publishingStatus'].nil? && !json_product['publishingStatus'].empty?
          product.publishing_status = json_product['publishingStatus']
        end

        # list 54
        # "IP" => "Available",
        # "NP" => "Not yet published",
        # "OP" => "Out of print",
        # "TU" => "Temporarily unavailable",
        if json_product['outOfPrint'] == '1' # Marked as Out of Print
          product.availability_code = 'OP'
        elsif json_product['status'] == 'P' # "Pre-Order" status
          product.availability_code = 'NP'
        elsif json_product['status'] == 'N' # "Out of Stock" status
          product.availability_code = 'TU'
        else
          product.availability_code = 'IP'
        end

        # Add various other text

        # "08" => "Review quote" (from list 33)
        if !json_product['reviewsText'].nil? && !json_product['reviewsText'].empty?
          product.add_other_text(8, json_product['reviewsText'])
        end

        # Add "25" => "Description for sales people"
        if !json_product['descriptionForSalesPeople'].nil? && !json_product['descriptionForSalesPeople'].empty?
          product.add_other_text(25, json_product['descriptionForSalesPeople'])
        end

        # Add "26" => "Description for press or other media"
        if !json_product['descriptionForPressOrOtherMedia'].nil? && !json_product['descriptionForPressOrOtherMedia'].empty?
          product.add_other_text(26, json_product['descriptionForPressOrOtherMedia'])
        end

        product.product_form = json_product['productForm']
        product.product_form_detail = json_product['productFormDetail']

        product.add_illustration(json_product['illustrationOtherContentType'])

        #product.on_order = 20
        product.on_hand = json_product['quantity']
        product.add_price(1, json_product['retail'].to_d, 'USD')
        product.add_price(1, json_product['retailCanada'].to_d, 'CAD')
        # product.rrp_exc_sales_tax = json_product['retail'].to_d

        # Carton Quantity
        if !json_product['packQuantity'].nil? && !json_product['packQuantity'].empty?
          product.pack_quantity = json_product['packQuantity'].to_d
        end

        writer << product
      end
      writer.end_document
    end

    # now just return an xml file, PHP will send it along as a download
    content_type 'text/xml'
    File.read(xml_out_filename)

    # content_type :json
    # {
    #   success: 1,
    #   writer: writer,
    #   file: xml_out_filename
    # }.to_json
  end
end
