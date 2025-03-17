# frozen_string_literal: true

class Folio::FileList::FileComponent < Folio::ApplicationComponent
  def initialize(file:,
                 file_klass: nil,
                 template: false,
                 editable: true,
                 destroyable: false,
                 primary_action: nil)
    @file = file
    @file_klass = file_klass || file.class
    @template = template
    @editable = editable
    @destroyable = destroyable
    @primary_action = primary_action
  end

  def data
    stimulus_controller("f-file-list-file",
                        values: {
                          file_type: @file_klass.to_s,
                          primary_action: @primary_action,
                          template_url:,
                        })
  end

  def image_wrap_style
    return if @file.blank?
    return if @file.additional_data.blank?
    return if @file.additional_data["dominant_color"].blank?

    "background-color: #{@file.additional_data["dominant_color"]}"
  end

  def destroy_url
    return @destroy_url unless @destroy_url.nil?

    @destroy_url = if @file.present? && @destroyable && @file_klass <= Folio::File
      controller.folio.url_for([:console, :api, @file])
    else
      false
    end
  end

  def template_url
    return nil unless @template

    controller.folio.file_list_file_folio_api_s3_path(file_type: @file_klass.to_s,
                                                      editable: @editable,
                                                      destroyable: @destroyable,
                                                      primary_action: @primary_action)
  end
end
