# frozen_string_literal: true

class Folio::Mux::DeleteMediaJob < Folio::ApplicationJob
  queue_as :default

  unique :until_and_while_executing

  MFileStruct = Struct.new(:remote_key)
  def perform(original_key)
    Folio::Mux::Api.new(MFileStruct.new(original_key)).delete_media
  end
end
