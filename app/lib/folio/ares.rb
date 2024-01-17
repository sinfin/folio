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
      response = HTTParty.get("https://ares.gov.cz/ekonomicke-subjekty-v-be/rest/ekonomicke-subjekty/#{identification_number}")

      if response.code != 200
        if response["kod"]
          msg = [response["kod"], response["subKod"], response["popis"]].compact.join(" / ")

          if ["NENALEZENO", "CHYBA_VSTUPU"].include?(response["kod"])
            raise InvalidIdentificationNumberError, msg
          else
            raise ParseError, msg
          end
        else
          raise ConnectionError, "#{response.code} #{response.message}"
        end
      end

      hash = begin
        JSON.parse(response.body)
      rescue StandardError => e
        raise ParseError, e.message
      end

      Subject.new(identification_number: hash["ico"],
                  vat_identification_number: hash["dic"],
                  company_name: hash["obchodniJmeno"],
                  city: hash.dig("sidlo", "nazevObce"),
                  address_line_1: hash.dig("sidlo", "nazevUlice"),
                  address_line_2: hash.dig("sidlo", "cisloDomovni").try(:to_s),
                  zip: hash.dig("sidlo", "psc").try(:to_s),
                  country_code: hash.dig("sidlo", "kodStatu") || "CZ")
    end
  end
end
