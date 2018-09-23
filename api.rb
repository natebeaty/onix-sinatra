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
    xml_out_filename = "public/output/onix-output-%s.xml" % json['onixData']['products'][0][0]['productId']

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

        product.width = json_product[0]['width']
        product.height = json_product[0]['height']
        product.thickness = json_product[0]['thickness']
        product.number_of_pages = json_product[0]['pageCount'].to_i

        # images
        product.thumbnail_url = json_product[0]['thumbnail']
        product.cover_url = json_product[0]['coverUrl']
        product.cover_url_hq = json_product[0]['coverUrlHq']

        # ? what is this
        product.proprietary_id = json_product[0]['productId']
        # also unsure of this
        product.record_reference = json_product[0]['productId']
        # do we need both isbn?
        product.isbn10 = json_product[0]['isbn10']
        product.isbn13 = json_product[0]['isbn13']

        product.title = json_product[0]['title']
        product.subtitle = json_product[0]['subtitle']
        product.main_description = json_product[0]['description']
        product.short_description = json_product[0]['shortDescription']
        product.add_contributor(json_product[0]['authorReverse'])

        # product.imprint = "Malhame"
        product.publisher = json_product[0]['publisher']

        # what's this?
        # product.sales_restriction_type = 0

        product.supplier_website = json_product[0]['supplier']['url']
        product.supplier_name = json_product[0]['supplier']['name']
        product.supplier_phone = json_product[0]['supplier']['phone']
        product.supplier_fax = json_product[0]['supplier']['fax']
        product.supplier_email = json_product[0]['supplier']['email']
        product.supply_country = "US"

        # subjects
        json_product[0]['bisacCodes'].each_with_index do |bisac_code, i|
          if i == 0
            product.bic_main_subject = bisac_code
          end
          product.add_bisac_subject(bisac_code)
        end

        # audience_range
        if !(json_product[0]['audienceRange'].nil? || json_product[0]['audienceRange'].empty?)
          product.audience_range = json_product[0]['audienceRange']
        end

        # 10  Not yet available (needs expectedshipdate)
        # 11  Awaiting stock (needs expectedshipdate)
        # 20  Available
        # 21  In stock
        product.product_availability = 20

        product.product_form = json_product[0]['productForm']
        product.product_form_detail = json_product[0]['productFormDetail']

        product.add_illustration(json_product[0]['illustrationOtherContentType'])

        #product.on_order = 20
        product.on_hand = json_product[0]['quantity']
        product.rrp_exc_sales_tax = json_product[0]['retail'].to_d

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
