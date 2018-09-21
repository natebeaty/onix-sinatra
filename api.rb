#require 'dotenv/load'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'onix'
require 'bigdecimal'
require 'bigdecimal/util'

get '/' do
  ONIX::Normaliser.process('sample.xml', 'newfile.xml')
  # reader = ONIX::Reader.new(File.join(File.dirname(__FILE__),"sample.xml"), ::ONIX::APAProduct)
end

post '/api' do
  json = JSON.parse(request.body.read)
  # puts "I got some JSON: #{json['inspect']}"
  xml_out_filename = 'output3.xml'

  File.open(xml_out_filename, 'w') do |output|
    header = ONIX::Header.new
    header.from_company = json['onixData']['from']['company']
    header.from_person  = json['onixData']['from']['person']
    header.from_email  = json['onixData']['from']['email']
    header.sent_date = Time.now

    writer = ONIX::Writer.new(output, header)

    # product = ONIX::Product.new

    json['onixData']['products'].each do |json_product|
      # content_type :json
      # return { :onix => json_product[0], :key2 => 'value2' }.to_json
      product = ONIX::APAProduct.new

      product.notification_type = 3
      product.measurement_system = :imperial

      product.width = json_product[0]['width']
      product.height = json_product[0]['height']
      product.thickness = json_product[0]['thickness']
      product.number_of_pages = json_product[0]['page_count'].to_i

      # images
      product.thumbnail_url = json_product[0]['thumbnail']
      product.cover_url = json_product[0]['cover_url']
      product.cover_url_hq = json_product[0]['cover_url_hq']

      # ? what is this
      product.proprietary_id = json_product[0]['product_id']
      # also unsure of this
      product.record_reference = json_product[0]['product_id']
      # do we need both isbn?
      product.isbn10 = json_product[0]['isbn10']
      product.isbn13 = json_product[0]['isbn13']

      product.title = json_product[0]['title']
      product.subtitle = json_product[0]['subtitle']
      product.add_contributor(json_product[0]['author_reverse'])

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

      # product.bic_subjects =
      # subjects
      json_product[0]['bisac_codes'].each do |bisac_code|
        # product.bic_main_subject = bisac_code
        product.add_bisac_subject(bisac_code)
      end

      # audience_range
      # json_product[0]['audience_range']


      # json_product[0]['description']
      # json_product[0]['productForm']
      # json_product[0]['productFormDetail']


      # 10  Not yet available (needs expectedshipdate)
      # 11  Awaiting stock (needs expectedshipdate)
      # 20  Available
      # 21  In stock
      product.product_availability = 20
      product.product_form = json_product[0]['product_form']

      # product.illustration_type = json_product[0]['illustrationOtherContentType']

      # product.product_form_detail = json_product[0]['product_form_detail']

      product.on_hand = json_product[0]['quantity']
      product.rrp_exc_sales_tax = json_product[0]['retail'].to_d
      #product.on_order = 20

      writer << product
    end
    writer.end_document
  end

  content_type 'text/xml'
  File.read(xml_out_filename)
  # response.headers['content_type'] = "application/octet-stream"
  # attachment(project.name+'.tga')
  # response.write(project.image)

  # content_type :json
  # {
  #   success: 1,
  #   writer: writer,
  #   file: xml_out_filename
  # }.to_json
end
