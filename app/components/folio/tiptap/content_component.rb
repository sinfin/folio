# frozen_string_literal: true

class Folio::Tiptap::ContentComponent < ApplicationComponent
  def initialize(record:, attribute: :tiptap_content, class_name: nil)
    @record = record
    @attribute = attribute
    @class_name = class_name
  end

  def render?
    tiptap_content.present?
  end

  private
    def tiptap_content
      @tiptap_content ||= @record.send(@attribute).presence
    end
end
