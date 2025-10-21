# frozen_string_literal: true

class Folio::Console::Files::ShowComponent < Folio::Console::ApplicationComponent
  TURBO_FRAME_ID = "folio-console-file-show"

  def initialize(file:)
    @file = file
  end

  def data
    stimulus_controller("f-c-files-show",
                        values: {
                          loading: false,
                          id: @file.id,
                          file_type: @file.class.to_s,
                          show_url: controller.folio.url_for([:console, @file]),
                          index_url: controller.folio.url_for([:console, @file.class])
                        },
                        action: {
                          "f-uppy:upload-success": "uppyUploadSuccess",
                          "f-c-files-show/message": "messageBusCallback",
                          "f-c-files-show:reload": "messageBusSuccess"
                        })
  end

  def download_button_model
    href = if @file.try(:private?)
      Folio::S3.url_rewrite(@file.file.remote_url(expires: 1.hour.from_now))
    else
      Folio::S3.cdn_url_rewrite(@file.file.remote_url)
    end

    {
      label: t(".download"),
      icon: :download,
      href:,
      target: "_blank",
      variant: :gray
    }
  end

  def destroy_button_model
    h = {
      label: t(".destroy"),
      icon: :delete,
      variant: :danger,
    }

    if @file.indestructible_reason
      h[:disabled] = true
    else
      h[:data] = stimulus_action({ click: "onDestroyClick" }, { url: url_for([:console, :api, @file]) })
    end

    h
  end

  def replace_button_model
    {
      label: t(".replace"),
      icon: :swap_horizontal,
      variant: :warning,
    }
  end

  def table_rows
    rows = {}

    if @file.class.included_modules.include?(Folio::File::HasUsageConstraints)
      rows = { usage_constraints: {} }
    end

    rows.merge!({
      attribution_source: {},
      author: {},
      headline: {},
      description: {},
      alt: {},
      attribution_source_url: {},
      attribution_copyright: {},
      attribution_licence: {},
    })

    rows.merge!(@file.console_show_additional_fields)
  end

  def autocomplete_for(key:, config:)
    return nil if config && (config[:as] == :integer || config[:collection])

    controller.folio.url_for([:field,
                              :console,
                              :api,
                              :autocomplete,
                              klass: @file.class.to_s,
                              field: key,
                              only_path: true])
  end

  def warning_for(key)
    return nil unless @file.file_placements_count > 0

    message_key = case key
    when :alt
      "missing_file_alt" if Rails.application.config.folio_files_require_alt && @file.class.human_type == "image" && @file.alt.blank?
    when :description
      "missing_file_description" if Rails.application.config.folio_files_require_description && @file.description.blank?
    when :author
      "missing_file_attribution" if Rails.application.config.folio_files_require_attribution && @file.author.blank?
    when :attribution_source
      "missing_file_attribution" if Rails.application.config.folio_files_require_attribution && @file.attribution_source.blank?
    end
    return nil unless message_key

    helpers.t("errors.messages.#{message_key}")
  end
end
