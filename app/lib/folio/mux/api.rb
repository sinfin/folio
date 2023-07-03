# frozen_string_literal: true

require "mux_ruby"

class Folio::Mux::Api
  API_ID = ENV["MUX_API_KEY"]
  API_SECRET = ENV["MUX_API_SECRET"]
  LOG_CALLS = ENV["MUX_LOG_CALLS"] == "true"

  MuxRuby.configure do |config|
    config.username = API_ID
    config.password = API_SECRET
  end

  attr_reader :media_file, :preview
  def initialize(media_file)
    @media_file = media_file
    @preview = false
  end


  def remote_key
    @remote_key ||= preview ? media_file.remote_preview_key : media_file.remote_key
  end

  def create_media(preview: false)
    rq = MuxRuby::CreateAssetRequest.new
    rq.mp4_support = "standard" # to be able get .m4a and .mp4

    if preview
      rq.input = [{ url: "mux://assets/#{media_file.remote_key}",
                    start_time: media_file.preview_starts_at_second,
                    end_time: media_file.preview_ends_at_second }]
      rq.playback_policy = [MuxRuby::PlaybackPolicy::PUBLIC]
    else
      rq.input = [{ url: media_file_content_url }]
      rq.playback_policy = [MuxRuby::PlaybackPolicy::SIGNED, MuxRuby::PlaybackPolicy::PUBLIC] # public to be abel to see content in Mux.com admin
    end

    rq.test = Rails.env.test? # max 10secs, erased after 24h, not count limited
    log_call("calling MUX #{rq.to_json}")
    response = assets_api.create_asset(rq)
    log_call("Response: #{response.to_json}")
    response
  end

  def check_media(preview: false)
    @preview = preview

    response = assets_api.get_asset(remote_key)
    log_call("Checked asset #{remote_key}: #{response.to_json}")
    # log_call("Checked asset info #{remote_key}: #{assets_api.get_asset_input_info(response.data.id)}")
    response
  end

  def request_mp4_support(preview: false)
    mp4_req = MuxRuby::UpdateAssetMP4SupportRequest.new
    mp4_req.mp4_support = "standard"

    response = assets_api.update_asset_mp4_support(remote_key, mp4_req)
    log_call("Request MP4 support #{remote_key}: #{response.to_json}")
    response
  end


  def update_file(preview: false)
    raise "Not Implemented"
  end


  def delete_media
    # media_file is struct set with correct (full/preview)_key as `remote_key`
    response = assets_api.delete_asset(remote_key)
    log_call("Deleted #{remote_key}: #{response.to_json}")
    response
  end

  def assets
    assets_api.list_assets()
  end

  def live_streams
    live_api.list_live_streams()
  end

  def direct_uploads
    uploads_api.list_direct_uploads()
  end

  def signing_keys
    keys_api.list_url_signing_keys()
  end


  private
    def assets_api
      @assets_api ||= MuxRuby::AssetsApi.new
    end

    def uploads_api
      @uploads_api ||= MuxRuby::DirectUploadsApi.new
    end

    def live_api
      @live_api ||= MuxRuby::LiveStreamsApi.new
    end

    def keys_api
      @keys_api ||= MuxRuby::URLSigningKeysApi.new
    end

    def media_file_content_url
      case Dragonfly.app.datastore
      when Dragonfly::S3DataStore
        media_file.file.remote_url(expires: 1.hour.from_now)
      when Dragonfly::FileDataStore
        fail
        # response = post(url, params)
        # absolute_path = Dragonfly.app.datastore.server_root + media_file.file.remote_url
        # upload_local(File.new(absolute_path), response)
      else
        fail
      end
    end

    def log_call(msg)
      Rails.logger.info msg if LOG_CALLS
    end
end
