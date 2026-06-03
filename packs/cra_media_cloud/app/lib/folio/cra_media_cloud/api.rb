# frozen_string_literal: true

module Folio
  module CraMediaCloud
    class Api
      def initialize
        fail "CraMediaCloud::Api: Missing base url" unless ENV["CRA_MEDIA_CLOUD_API_BASE_URL"]
        fail "CraMediaCloud::Api: Missing credentials" unless ENV["CRA_MEDIA_CLOUD_API_USERNAME"] && ENV["CRA_MEDIA_CLOUD_API_PASSWORD"]

        @base_url = ENV["CRA_MEDIA_CLOUD_API_BASE_URL"]
        @username = ENV["CRA_MEDIA_CLOUD_API_USERNAME"]
        @password = ENV["CRA_MEDIA_CLOUD_API_PASSWORD"]
      end

      def get_jobs(params = {})
        request(:get, "jobs", params)
      end

      def get_job(job_id)
        request(:get, "jobs/#{job_id}")
      end

      def delete_job_content(job_id)
        request(:delete, "jobs/#{job_id}/content")
      end

      private
        def request(method, key, params = {})
          params.transform_keys! { |key| key.to_s.camelize(:lower) }

          uri = URI.parse([@base_url, "manage", @username, key].join("/"))
          uri.query = URI.encode_www_form(params) if params.present?

          request = case method
                    when :get
                      Net::HTTP::Get.new(uri)
                    when :delete
                      Net::HTTP::Delete.new(uri)
          end

          request.basic_auth(@username, @password)

          response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

          if response.is_a?(Net::HTTPSuccess)
            if response.body.present?
              JSON.parse(response.body)
            else
              true
            end
          else
            raise "CraMediaCloud::Api: Request failed with status #{response.code}"
          end
        end
    end
  end
end
