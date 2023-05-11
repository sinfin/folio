# frozen_string_literal: true

class Folio::JwPlayer::DeleteMediaJob < Folio::ApplicationJob
  queue_as :default

  MFileStruct = Struct.new(:remote_key)
  def perform(original_key)
    Folio::JwPlayer::Api.new(MFileStruct.new(original_key)).delete_media
  end
end
