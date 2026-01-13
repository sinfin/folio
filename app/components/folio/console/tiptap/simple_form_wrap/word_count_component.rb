# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrap::WordCountComponent < Folio::Console::ApplicationComponent
  def initialize(attribute_name:, data: nil)
    @attribute_name = attribute_name
    @data = data || {}
  end

  def controller_data
    stimulus_merge(@data,
                  stimulus_controller("f-c-tiptap-simple-form-wrap-word-count",
                                      values: {
                                        attribute_name: @attribute_name,
                                      },
                                      action: {
                                        "f-c-tiptap-simple-form-wrap:updateWordCount" => "updateWordCount",
                                      }))
  end
end
