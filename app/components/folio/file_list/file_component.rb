# frozen_string_literal: true

class Folio::FileList::FileComponent < Folio::ApplicationComponent
  def initialize(file:,
                 file_klass: nil,
                 template: false,
                 editable: true,
                 destroyable: false,
                 selectable: false,
                 primary_action: nil)
    @file = file
    @file_klass = file_klass || file.class
    @template = template
    @editable = editable
    @destroyable = destroyable
    @selectable = selectable
    @primary_action = primary_action
  end

  def data
    stimulus_controller("f-file-list-file",
                        values: {
                          file_type: @file_klass.to_s,
                          id: @file ? @file.id : "",
                          primary_action: @primary_action,
                          selectable: @selectable,
                          editable: @editable,
                          destroyable: @destroyable
                        },
                        action: @editable ? {
                          "f-c-files-show/deleted@document": "filesShowDeleted"
                        } : nil)
  end

  def image_bg_style
    return if @file.blank?
    return if @file.additional_data.blank?
    return if @file.additional_data["dominant_color"].blank?

    "background-color: #{@file.additional_data["dominant_color"]}"
  end

  def modal_api_url
    return @modal_api_url unless @modal_api_url.nil?

    @modal_api_url = if @file.present? && @file_klass <= Folio::File
      controller.folio.url_for([:console, :api, @file])
    else
      false
    end
  end

  def destroy_url
    return @destroy_url unless @destroy_url.nil?

    @destroy_url = if @file.present? && @destroyable
      if @file_klass <= Folio::File
        url_for([:console, :api, @file])
      else
        # TODO handle private/session attachments
        false
      end
    else
      false
    end
  end

  def template_url
    return nil unless @template

    controller.folio.file_list_file_folio_api_s3_path(file_type: @file_klass.to_s,
                                                      editable: @editable,
                                                      destroyable: @destroyable,
                                                      selectable: @selectable,
                                                      primary_action: @primary_action)
  end

  def indestructible_reason
    return @indestructible_reason unless @indestructible_reason.nil?

    @indestructible_reason = if @file.present? && @file.try(:indestructible_reason).present?
      @file.indestructible_reason
    else
      false
    end
  end

  def unmet_requirements
    return unless @file
    return if @unmet_requirements == false

    ary = []

    if Rails.application.config.folio_files_require_attribution
      if author.blank? && attribution_source.blank? && attribution_source_url.blank?
        ary << I18n.t("errors.messages.missing_file_attribution").capitalize
      end
    end

    if Rails.application.config.folio_files_require_alt
      if alt.blank?
        ary << I18n.t("errors.messages.missing_file_alt").capitalize
      end
    end

    if Rails.application.config.folio_files_require_description
      if description.blank?
        ary << I18n.t("errors.messages.missing_file_description").capitalize
      end
    end

    @unmet_requirements = ary.presence || false
  end

  def unmet_requirements_html
    unmet_requirements.map do |str|
      content_tag(:p, str, class: "mb-0 text-danger")
    end.join(" ")
  end

  def file_information_rows
    return [] if @file.blank?

    ary = []

    if description = @file.try(:description).presence
      ary << description
    end

    %i[
      alt
      author
    ].each do |key|
      if value = @file.try(key).presence
        ary << "#{@file_klass.human_attribute_name(key)}: #{value}"
      end
    end

    if value = @file.try(:file_list_source).presence
      ary << "#{@file_klass.human_attribute_name(:attribution_source)}: #{value}"
    end

    ary
  end

  def primary_action_data
    @primary_action_data ||= stimulus_action({ click: "edit" }, { url: modal_api_url })
  end

  def download_href
    if @file.try(:private?)
      Folio::S3.url_rewrite(@file.file.remote_url(expires: 1.hour.from_now))
    else
      Folio::S3.cdn_url_rewrite(@file.file.remote_url)
    end
  end
end
