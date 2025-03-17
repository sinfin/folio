# frozen_string_literal: true

class Folio::FileList::FileComponent < Folio::ApplicationComponent
  def initialize(file:, file_klass: nil, template: false)
    @file = file
    @file_klass = file_klass || file.class
    @template = template
  end

  def data
    stimulus_controller("f-file-list-file",
                        values: {
                          file_type: @file_klass.to_s,
                        })
  end

  def image_wrap_style
    return if @file.blank?
    return if @file.additional_data.blank?
    return if @file.additional_data["dominant_color"].blank?

    "background-color: #{@file.additional_data["dominant_color"]}"
  end
end
