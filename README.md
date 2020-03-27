onix-sinatra
============

Why hasn't anyone else written this?

Still in early stages. I imagine this will get ugly.

Using a fork of the [many-forked ruby onix gem](https://github.com/natebeaty/onix) that I've mangled questionably.

Also: ONIX sucks.

## Usage

Set up your env file with `cp .env.example .env` and set an API key to validate requests.

Set up `rbenv` and `rbenv install 2.7.0` to match `.ruby-version` then `gem install bundler && bundle install`.

If you have Fabric 1.4 you can run `fab dev` to fire up the app listening on http://127.0.0.1:9292

This accepts JSON requests and spits out ONIX xml files, e.g.:

```
{
    "json": {
        "onixType": "2.1",
        "onixData": {
            "from": {
                "company": "Your Company",
                "person": "Your Name",
                "email": "you@email.com"
            },
            "supplier": {
                "name": "ePubDirect",
                "availabilityCode": "IP"
            },
            "products": [
                {
                    "productId": "555",
                    "isbn13": "ISBNHERE",
                    "title": "Test Title",
                    "subtitle": "",
                    "url": "http:\/\/foo.com\/test-title",
                    "status": "A",
                    "outOfPrint": "0",
                    "quantity": "136",
                    "retail": "3.00",
                    "retailCanada": "4.00",
                    "publishDate": "2006-04-19",
                    "shipDate": "2006-04-19",
                    "distributor": null,
                    "publisher": "Publisher, LLC",
                    "imprint": "",
                    "authors": [
                        {
                            "name": "Nate Beaty",
                            "nameReverse": "Beaty, Nate",
                            "bio": "Total an author bio",
                            "role": "Author",
                            "roleCode": "A01"
                        }
                    ],
                    "width": "7.50",
                    "height": "5.00",
                    "thickness": "0.10",
                    "thumbnail": "",
                    "coverUrl": "",
                    "coverUrlHq": "",
                    "interiors": [],
                    "audienceRange": "",
                    "pageCount": "",
                    "description": "Totally an example description.",
                    "shortDescription": "",
                    "illustrationOtherContentType": "",
                    "productForm": "",
                    "productFormDetail": "",
                    "EpubType": "",
                    "productAvailability": "",
                    "publishingStatus": "",
                    "packQuantity": "",
                    "descriptionForSalesPeople": "",
                    "descriptionForPressOrOtherMedia": "",
                    "seriesTitle": "fooo",
                    "numberWithinSeries": "",
                    "editionNumber": "",
                    "bisacCodes": [],
                    "compTitles": [],
                    "fullCompTitles": [],
                    "eBooks": [
                        ""
                    ],
                    "reviewsText": "",
                    "supplier": {
                        "url": "foo.com",
                        "name": "Supplier Name",
                        "phone": "555-555-5555",
                        "fax": "555-555-5555",
                        "email": "you@email.com"
                    }
                }
            ]
        }
    }
}
```

Spits out `onix-555.xml` with:

```
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ONIXMessage SYSTEM "http://www.editeur.org/onix/2.1/03/reference/onix-international.dtd">
<ONIXMessage release="2.1">
<Header>
  <FromCompany>Your Company</FromCompany>
  <FromPerson>Your Name</FromPerson>
  <FromEmail>you@email.com</FromEmail>
  <SentDate>20200327</SentDate>
</Header>
<Product>
  <RecordReference>555</RecordReference>
  <NotificationType>03</NotificationType>
  <ProductIdentifier>
    <ProductIDType>01</ProductIDType>
    <IDValue>555</IDValue>
  </ProductIdentifier>
  <ProductIdentifier>
    <ProductIDType>15</ProductIDType>
    <IDValue>ISBNHERE</IDValue>
  </ProductIdentifier>
  <Series>
    <TitleOfSeries>Series Title</TitleOfSeries>
  </Series>
  <Title>
    <TitleType>01</TitleType>
    <TitleText>Test Title</TitleText>
  </Title>
  <Website>
    <WebsiteRole>02</WebsiteRole>
    <WebsiteLink>http:\/\/foo.com\/test-title>
  </Website>
  <Contributor>
    <SequenceNumber>1</SequenceNumber>
    <ContributorRole>A01</ContributorRole>
    <PersonName>Nate Beaty</PersonName>
    <PersonNameInverted>Beaty, Nate</PersonNameInverted>
    <BiographicalNote>Total an author bio</BiographicalNote>
  </Contributor>
  <Language>
    <LanguageRole>01</LanguageRole>
    <LanguageCode>eng</LanguageCode>
  </Language>
  <NumberOfPages>0</NumberOfPages>
  <OtherText>
    <TextTypeCode>01</TextTypeCode>
    <TextFormat>06</TextFormat>
    <Text>Totally an example description.</Text>
  </OtherText>
  <Publisher>
    <PublishingRole>01</PublishingRole>
    <PublisherName>Your Company</PublisherName>
  </Publisher>
  <PublicationDate>20060419</PublicationDate>
  <SalesRights>
    <SalesRightsType>02</SalesRightsType>
    <RightsTerritory>WORLD</RightsTerritory>
  </SalesRights>
  <Measure>
    <MeasureTypeCode>02</MeasureTypeCode>
    <Measurement>7.50</Measurement>
    <MeasureUnitCode>in</MeasureUnitCode>
  </Measure>
  <Measure>
    <MeasureTypeCode>01</MeasureTypeCode>
    <Measurement>5.00</Measurement>
    <MeasureUnitCode>in</MeasureUnitCode>
  </Measure>
  <Measure>
    <MeasureTypeCode>03</MeasureTypeCode>
    <Measurement>0.10</Measurement>
    <MeasureUnitCode>in</MeasureUnitCode>
  </Measure>
  <RelatedProduct>
    <RelationCode>13</RelationCode>
    <ProductIdentifier>
      <ProductIDType>15</ProductIDType>
      <IDValue/>
    </ProductIdentifier>
  </RelatedProduct>
  <SupplyDetail>
    <SupplierName>Supplier Name</SupplierName>
    <TelephoneNumber>555-555-5555</TelephoneNumber>
    <FaxNumber>555-555-5555</FaxNumber>
    <EmailAddress>you@email.com</EmailAddress>
    <OnSaleDate>20060419</OnSaleDate>
    <Stock>
      <OnHand>136</OnHand>
    </Stock>
    <Price>
      <PriceTypeCode>01</PriceTypeCode>
      <PriceAmount>3.0</PriceAmount>
      <CurrencyCode>USD</CurrencyCode>
      <CountryCode>US</CountryCode>
    </Price>
    <Price>
      <PriceTypeCode>01</PriceTypeCode>
      <PriceAmount>4.0</PriceAmount>
      <CurrencyCode>CAD</CurrencyCode>
      <CountryCode>CA</CountryCode>
    </Price>
    <Price>
      <PriceTypeCode>01</PriceTypeCode>
      <PriceAmount>3.0</PriceAmount>
      <CurrencyCode>USD</CurrencyCode>
      <Territory>ROW</Territory>
    </Price>
  </SupplyDetail>
</Product>
</ONIXMessage>
```
