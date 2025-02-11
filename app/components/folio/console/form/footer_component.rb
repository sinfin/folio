# frozen_string_literal: true

class Folio::Console::Form::FooterComponent < Folio::Console::ApplicationComponent
  def initialize(f: nil, preview_path: nil)
    @f = f
    @record = @f ? @f.object : nil
    @preview_path = preview_path
  end

  def before_render
    if @record
      @audit = controller.instance_variable_get(:@audited_audit)

      @share_url = controller.through_aware_console_url_for(@record,
                                                            action: :edit,
                                                            hash: { only_path: false },
                                                            safe: true)
    end
  end

  def preview_path_with_default
    return if @preview_path == false
    return @preview_path if @preview_path

    return unless @record.persisted?

    preview_url_for(@record)
  rescue NoMethodError
  end

  def data
    stimulus_controller("f-c-form-footer",
                        values: {
                          status: "saved",
                        },
                        action: {
                          "message@window" => "onWindowMessage",
                          "change@document" => "onDocumentChange",
                          "folioConsoleCustomChange@document" => "onDocumentChange",
                          "submit@document" => "onDocumentSubmit"
                        })
  end

  def saved_at_tooltip
    if @record && @record.created_at
      title = "#{t(".saved")} #{l(@record.created_at, format: :console_short_with_seconds)}"
      stimulus_tooltip(title, placement: :right)
    end
  end
end
