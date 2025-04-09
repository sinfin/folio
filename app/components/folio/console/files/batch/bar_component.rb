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

  def can_batch_delete
    return @can_batch_delete unless @can_batch_delete.nil?
    @can_batch_delete = can? :destroy, @file_klass
  end

  def buttons_model
    return [] if files_ary.blank?

    ary = []

    if files_ary.all? { |file| can_now?(:destroy, file) }
      ary << {
        variant: :danger,
        icon: :delete,
        label: t(".delete"),
        confirm: true,
      }
    end

    ary << {
      variant: :medium_dark,
      icon: :download,
      label: t(".download"),
    }

    if files_ary.all? { |file| can_now?(:update, file) }
      ary << {
        variant: :medium_dark,
        icon: :menu,
        label: t(".settings"),
      }
    end

    ary
  end
end
