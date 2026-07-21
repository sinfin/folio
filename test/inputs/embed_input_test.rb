# frozen_string_literal: true

require "test_helper"

class EmbedInputTest < Folio::Console::CellTest
  class InvalidEmbedRecord
    include ActiveModel::Model

    attr_accessor :folio_embed_data
  end

  test "renders validation errors below the embed field before the preview" do
    record = InvalidEmbedRecord.new(folio_embed_data: {
                                      "active" => true,
                                      "type" => "youtube",
                                      "url" => "https://www.youtube.com/watch?v=8DPcXHMGMBc"
                                    })
    record.errors.add(:folio_embed_data, :invalid)

    page = ::Capybara.string(render_embed_input(record))
    error = record.errors.full_messages_for(:folio_embed_data).to_sentence

    assert page.has_css?(".f-input-embed-inner__input-wrap textarea.is-invalid + .invalid-feedback",
                         text: error)
    assert_not page.has_css?(".f-input-embed > .invalid-feedback")
  end

  private
    def render_embed_input(record)
      html = nil

      controller.view_context.simple_form_for(record, url: "/", method: :get) do |f|
        html = f.input(:folio_embed_data, as: :embed)
      end

      html
    end
end
