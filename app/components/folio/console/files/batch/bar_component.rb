# frozen_string_literal: true

class Folio::Console::Files::Batch::BarComponent < Folio::Console::ApplicationComponent
  def initialize(file_klass:)
    @file_klass = file_klass
  end

  def data
    stimulus_controller("f-c-files-batch-bar",
                        values: {
                          base_api_url: url_for([:console, :api, @file_klass]),
                          loading: false,
                          file_ids_json: file_ids.to_json,
                        },
                        action: {
                          "f-c-files-batch-bar/action" => "batchActionFromFile"
                        })
  end

  def file_ids
    @file_ids ||= session.dig(Folio::Console::Api::FileControllerBase::BATCH_SESSION_KEY, @file_klass.to_s, "file_ids") || []
  end

  def files_ary
    @files_ary ||= file_ids.present? ? @file_klass.where(id: file_ids).to_a : []
  end

  def buttons_data
    return [] if files_ary.blank?

    ary = []

    if files_ary.all? { |file| can_now?(:destroy, file) }
      indestructible_file = files_ary.find { |file| file.indestructible_reason }

      base = { variant: :danger, icon: :delete, label: t(".delete") }

      if indestructible_file.present?
        base[:disabled] = true
        ary << [stimulus_tooltip(indestructible_file.indestructible_reason), base]
      else
        base[:data] = stimulus_action("delete")
        ary << [nil, base]
      end
    end

    ary << [nil, {
      variant: :medium_dark,
      icon: :download,
      label: t(".download"),
      data: stimulus_action("download")
    }]

    if files_ary.all? { |file| can_now?(:update, file) }
      ary << [nil, {
        variant: :medium_dark,
        icon: :menu,
        label: t(".settings"),
        data: stimulus_action("settings")
      }]
    end

    ary
  end
end
