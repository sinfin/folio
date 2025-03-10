# frozen_string_literal: true

class Folio::Console::SharePreviewModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME_BASE = "f-c-share-preview-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  def initialize(record:)
    @record = record
  end

  def before_render
    @preview_url = preview_url_for(@record)
  end
end
