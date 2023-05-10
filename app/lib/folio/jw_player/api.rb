# frozen_string_literal: true

require "uri"
require "net/http"
require "openssl"

class Folio::JwPlayer::Api
  SITE_ID = ENV.fetch("JWPLAYER_API_KEY")
  SECRET = ENV.fetch("JWPLAYER_API_SECRET")
  LOG_CALLS = ENV.fetch("JWPLAYER_LOG_CALLS") == "true"

  attr_reader :media_file, :preview
  def initialize(media_file)
    @media_file = media_file
    @preview = false
  end

  def base_uri
    URI("https://api.jwplayer.com/v2/sites/#{SITE_ID}/media/")
  end

  def media_uri
    URI(base_uri.to_s + remote_key)
  end

  def remote_key
    @remote_key ||= preview ? media_file.remote_preview_key : media_file.remote_key
  end

  def create_media(preview: false)
    @preview = preview

    post(base_uri, params(preview))
  end

  def check_media(preview: false)
    @preview = preview
    get(media_uri)
  end

  def update_file(preview: false)
    @preview = preview

    patch(media_uri, params(preview))
  end

  def delete_media
    # media_file is struct set with correct (full/preview)_key as `remote_key`
    delete(media_uri)
  end

  private
    def params(preview = false)
      metadata = {
        title: media_file.file_name + (preview ? " - preview" : ""),
        author: media_file.author,
        description: media_file.description,
        tags: media_file.tag_list.join(",").presence,
        # external_id: "TESTx" + media_file.id.to_s
      }.compact

      upload_data = {}
      case Dragonfly.app.datastore
      when Dragonfly::S3DataStore
        upload_data = { download_url: media_file.file.remote_url(expires: 1.hour.from_now),
                        method: "fetch" }
      when Dragonfly::FileDataStore
        fail
        # response = post(url, params)
        # absolute_path = Dragonfly.app.datastore.server_root + media_file.file.remote_url
        # upload_local(File.new(absolute_path), response)
      else
        fail
      end
      if preview
        start_duration = ActiveSupport::Duration.build(media_file.preview_starts_at_second).parts
        end_duration = ActiveSupport::Duration.build(media_file.preview_ends_at_second).parts
        upload_data[:trim_in_point] = %i[hours, minutes, seconds].collect { |k| "%02d" % (start_duration[k] || 0) }.join(":")
        upload_data[:trim_out_point] = %i[hours, minutes, seconds].collect { |k| "%02d" % (end_duration[k] || 0)  }.join(":")
      end

      { metadata:, upload: upload_data }
    end



    def upload_local(file, response_json)
      # link = response_json["link"]
      # link["query"]["api_format"] = "json"

      # upload_url = URI::Generic.build(scheme: link["protocol"],
      #                                 host: link["address"],
      #                                 path: link["path"],
      #                                 query: link["query"].to_query)
      # res = RestClient.post(upload_url.to_s, file:)
      # JSON.parse(res)
    end

    def post(uri, params)
      request = Net::HTTP::Post.new(uri.request_uri)
      request["content-type"] = "application/json"
      request.body = params.to_json

      call_api(uri, request)
    end

    def get(uri)
      request = Net::HTTP::Get.new(uri.request_uri)
      call_api(uri, request)
    end

    def patch(uri)
      request = Net::HTTP::Patch.new(uri.request_uri)
      call_api(uri, request)
    end

    def delete(uri)
      request = Net::HTTP::Delete.new(uri.request_uri)
      call_api(uri, request)
    end

    def call_api(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request["accept"] = "application/json"
      request["Authorization"] = "Bearer #{SECRET}"

      log_call("Calling JWPlayer #{uri} with #{request.to_json}")

      response = http.request(request)
      json = JSON.parse(response.read_body || "{}")

      log_call("Got JWPlayer response #{response.to_json}  with body: #{json}")


      raise "Response #{response.code}: #{json["errors"]}" if json["errors"].present?
      json
    end

    def log_call(msg)
      Rails.logger.info msg if LOG_CALLS
    end
end
