# frozen_string_literal: true

class Folio::Console::Files::Show::EncodingInfoComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
    @rsd = file.remote_services_data || {}
  end

  def render?
    cra_file? && (processing? || failed?)
  end

  def processing?
    @file.processing?
  end

  def failed?
    @file.processing_failed?
  end

  def retrying?
    failed? && @rsd["retry_scheduled_at"].present? && @rsd["retry_count"].to_i < 2
  end

  def current_phase
    @rsd["current_phase"]
  end

  def current_phase_label
    return current_phase&.humanize if current_phase.blank?

    encoding_phase = @rsd["current_encoding_phase"]
    processing_phases = @rsd["processing_phases"].to_i

    if processing_phases > 1 && encoding_phase.present?
      phase_name = @file.try(:encoder_phase_name, encoding_phase)
      if phase_name
        t(".phase_#{current_phase}_named",
          name: phase_name,
          default: t(".phase_#{current_phase}", default: current_phase.humanize))
      else
        t(".phase_#{current_phase}_multi",
          phase: encoding_phase,
          total: processing_phases,
          default: t(".phase_#{current_phase}", default: current_phase.humanize))
      end
    else
      t(".phase_#{current_phase}", default: current_phase.humanize)
    end
  end

  def encoding_progress
    @rsd["progress_percentage"]
  end

  def data
    {
      "controller" => "f-c-files-show-encoding-info",
      "f-c-files-show-encoding-info-file-id-value" => @file.id,
    }
  end

  private
    def cra_file?
      @file.try(:processing_service) == "cra_media_cloud" ||
        @rsd["current_phase"].present? ||
        @rsd["retry_count"].present?
    end
end
