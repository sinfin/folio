# frozen_string_literal: true

class Folio::Console::Files::ShowComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def data
    stimulus_controller("f-c-files-show",
                        values: {
                          loading: false,
                          id: @file.id,
                          file_type: @file.class.to_s,
                          show_url: controller.folio.url_for([:console, :api, @file])
                        },
                        action: {
                          "f-uppy:upload-success": "uppyUploadSuccess",
                          "f-c-files-show/message": "messageBusCallback"
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

  def table_row_keys
    %i[
      author
      attribution_source
      attribution_source_url
      attribution_copyright
      attribution_licence
      alt
    ]
  end

  def autocomplete_for(key)
    controller.folio.url_for([:field,
                              :console,
                              :api,
                              :autocomplete,
                              klass: @file.class.to_s,
                              field: key,
                              only_path: true])
  end
end
