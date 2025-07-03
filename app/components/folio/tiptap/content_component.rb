# frozen_string_literal: true

class Folio::Tiptap::ContentComponent < ApplicationComponent
  def initialize(record:, attribute: :tiptap_content)
    @record = record
    @attribute = attribute
  end

  def render?
    tiptap_content.present?
  end

  private
    def tiptap_content
      @tiptap_content ||= @record.send(@attribute).presence
    end
end
