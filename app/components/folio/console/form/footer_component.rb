# frozen_string_literal: true

class Folio::Console::Form::FooterComponent < Folio::Console::ApplicationComponent
  def initialize(f: nil, preview_path: nil)
    @f = f
    @preview_path = preview_path
  end

  def preview_path_with_default
    return if @preview_path == false
    return @preview_path if @preview_path

    return unless @f
    return unless @f.object.persisted?

    preview_url_for(@f.object)
  rescue NoMethodError
  end

  def data
    stimulus_controller("f-c-form-footer",
                        values: {
                          status: "saved",
                        })
  end

  def saved_at_tooltip
    if @f.object.created_at
      title = "#{t(".saved")} #{l(@f.object.created_at, format: :console_short_with_seconds)}"
      stimulus_tooltip(title, placement: :right)
    end
  end
end
