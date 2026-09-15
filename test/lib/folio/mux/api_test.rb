# frozen_string_literal: true

require "test_helper"

class Folio::Mux::ApiTest < ActiveSupport::TestCase
  test "preview asset request uses current Mux SDK fields" do
    media_file = Struct.new(:remote_key, :preview_starts_at_second, :preview_ends_at_second)
                       .new("full-asset", 2, 8)
    api = Folio::Mux::Api.new(media_file)
    requests = []
    assets_api = Object.new
    assets_api.define_singleton_method(:create_asset) do |request|
      requests << request
      {}
    end
    api.instance_variable_set(:@assets_api, assets_api)

    api.create_media(preview: true)

    payload = requests.sole.to_hash
    assert_equal [{ url: "mux://assets/full-asset", start_time: 2, end_time: 8 }], payload[:inputs]
    assert_equal [MuxRuby::PlaybackPolicy::PUBLIC], payload[:playback_policies]
    assert_not payload.key?(:input)
    assert_not payload.key?(:playback_policy)
  end
end
