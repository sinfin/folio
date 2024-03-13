# frozen_string_literal: true

class Folio::SesionAttachments::DropzoneComponent < ApplicationComponent
  def initialize(klass:, prompt: nil, max_file_size: 100, hint: nil)
    @klass = klass
    @prompt = prompt
    @max_file_size = max_file_size
    @hint = hint
  end

  def folio_dropzone
    render(Folio::DropzoneComponent.new(file_type: @klass.to_s,
                                        file_human_type: @klass.human_type,
                                        max_file_size: @max_file_size,
                                        destroy_url:,
                                        index_url:,
                                        prompt: @prompt || t(".prompt"),
                                        hint: @hint.nil? ? t(".hint") : @hint))
  end

  def index_url
    controller.folio.folio_session_attachments_path(format: :json)
  end

  def destroy_url
    controller.folio.folio_session_attachments_path("ID", format: :json)
  end
end
