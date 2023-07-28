# frozen_string_literal: true

require "httpparty"

module Folio
  module Ares
    Subject = Struct.new(:identification_number,
                         :vat_identification_number,
                         :company_name,
                         :city,
                         :address_line_1,
                         :address_line_2,
                         :zip,
                         :country_code,
                         keyword_init: true)

    class ConnectionError < StandardError; end
    class ARESError < StandardError; end
    class ParseError < StandardError; end
    class InvalidIdentificationNumberError < StandardError; end

    def self.get(identification_number)
      get!(identification_number)
    rescue ConnectionError,
           ARESError,
           ParseError,
           InvalidIdentificationNumberError
      Subject.new
    end

    def self.get!(identification_number)
      query = {
        ver: "1.0.3",
        ico: identification_number,
      }.to_query

      response = HTTParty.get("http://wwwinfo.mfcr.cz/cgi-bin/ares/darv_bas.cgi?#{query}")

      if response.code != 200
        raise ConnectionError, "#{response.code} #{response.message}"
      end

      xml = begin
        Nokogiri::XML(response.body)
      rescue StandardError => e
        raise ParseError, e.message
      end

      if error_text = xml.xpath("//D:ET")[0]&.text
        msg = error_text.strip

        if msg == "Chyba 23 - chyba ic" || msg.include?("nenalezeno")
          raise InvalidIdentificationNumberError, msg
        else
          raise ARESError, msg
        end
      end

      Subject.new(identification_number: xml.xpath("//D:ICO")[0]&.text,
                  vat_identification_number: xml.xpath("//D:DIC")[0]&.text,
                  company_name: xml.xpath("//D:OF")[0]&.text,
                  city: xml.xpath("//D:N")[0]&.text,
                  address_line_1: xml.xpath("//D:NU")[0]&.text,
                  address_line_2: xml.xpath("//D:CD")[0]&.text,
                  zip: xml.xpath("//D:PSC")[0]&.text,
                  country_code: "CZ")
    end
  end
end
