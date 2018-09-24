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

  get '/' do
    status 403
    'Bad request.'
  end

  get '/test' do
    'Hello!'
  end

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
    xml_out_filename = "public/output/onix-output-%s.xml" % json['onixData']['products'][0]['productId']

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

        json_product['authors'].each do |author|
          product.add_contributor(author['nameReverse'], author['bio'])
        end

        product.add_contributor(json_product['authorReverse'], json_product['authorBio'])

        product.width = json_product['width']
        product.height = json_product['height']
        product.thickness = json_product['thickness']
        product.number_of_pages = json_product['pageCount'].to_i

        # images
        product.thumbnail_url = json_product['thumbnail']
        product.cover_url = json_product['coverUrl']
        product.cover_url_hq = json_product['coverUrlHq']

        # ? what is this
        product.proprietary_id = json_product['productId']
        # also unsure of this
        product.record_reference = json_product['productId']
        # do we need both isbn?
        product.isbn10 = json_product['isbn10']
        product.isbn13 = json_product['isbn13']

        # product.imprint = "Malhame"
        product.publisher = json_product['publisher']
        product.publisher_website = json_product['url']

        # what's this?
        # product.sales_restriction_type = 0

        # this sets <website> type 12, "A webpage devoted to an individual work, and maintained by a third party (eg a fan site)"
        # product.supplier_website = json_product['supplier']['url']
        product.supplier_name = json_product['supplier']['name']
        product.supplier_phone = json_product['supplier']['phone']
        product.supplier_fax = json_product['supplier']['fax']
        product.supplier_email = json_product['supplier']['email']
        product.supply_country = "US"

        # subjects
        json_product['bisacCodes'].each_with_index do |bisac_code, i|
          if i == 0
            product.bic_main_subject = bisac_code
          end
          product.add_bisac_subject(bisac_code)
        end

        # comp titles
        json_product['compTitles'].each do |isbn|
          product.add_comp_title(isbn)
        end

        # audience_range
        if !(json_product['audienceRange'].nil? || json_product['audienceRange'].empty?)
          product.audience_range = json_product['audienceRange']
        end

        # 10  Not yet available (needs expectedshipdate)
        # 11  Awaiting stock (needs expectedshipdate)
        # 20  Available
        # 21  In stock
        product.product_availability = 20

        product.product_form = json_product['productForm']
        product.product_form_detail = json_product['productFormDetail']

        product.add_illustration(json_product['illustrationOtherContentType'])

        #product.on_order = 20
        product.on_hand = json_product['quantity']
        product.rrp_exc_sales_tax = json_product['retail'].to_d

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
