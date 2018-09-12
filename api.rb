require 'sinatra'
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

  File.open('output3.xml', 'w') do |output|
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

      # images
      product.thumbnail_url = json_product[0]['thumbnail']
      product.cover_url = json_product[0]['cover_url']
      product.cover_url_hq = json_product[0]['cover_url_hq']

      product.number_of_pages = json_product[0]['page_count'].to_i

      # json_product[0]['audience_range']
      # json_product[0]['description']
      # json_product[0]['illustrationOtherContentType']
      # json_product[0]['productForm']
      # json_product[0]['productFormDetail']

      product.proprietary_id = json_product[0]['product_id']
      product.record_reference = json_product[0]['product_id']
      product.isbn10 = json_product[0]['isbn10']
      product.isbn13 = json_product[0]['isbn13']
      product.title = json_product[0]['title']
      product.subtitle = json_product[0]['subtitle']
      product.add_contributor(json_product[0]['author_reverse'])
      product.imprint = "Malhame"
      product.publisher = json_product[0]['publisher']
      product.sales_restriction_type = 0
      product.supplier_website = json_product[0]['supplier']['url']
      product.supplier_name = json_product[0]['supplier']['name']
      product.supplier_phone = json_product[0]['supplier']['phone']
      # product.supplier_fax = json_product[0]['supplier']['phone']
      product.supplier_email = json_product[0]['supplier']['email']
      product.supply_country = "US"
      # product.bic_subjects =

      json_product[0]['bisac_codes'].each do |bisac_code|
        # product.bic_main_subject = bisac_code
        product.add_bisac_subject bisac_code
      end

      # 10  Not yet available (needs expectedshipdate)
      # 11  Awaiting stock (needs expectedshipdate)
      # 20  Available
      # 21  In stock
      product.product_availability = 20
      product.product_form = json_product[0]['product_form']
      # product.product_form_detail = json_product[0]['product_form_detail']

      product.on_hand = json_product[0]['quantity']
      product.rrp_exc_sales_tax = json_product[0]['retail'].to_d
      #product.on_order = 20

      writer << product
    end
    writer.end_document
  end

  content_type :json
  { :onix => json['onixData']['products'][0][0], :key2 => 'value2' }.to_json
end
