# frozen_string_literal: true

class Folio::Console::Form::FooterComponent < Folio::Console::ApplicationComponent
  def initialize(f: nil, preview_path: nil, share_preview: false)
    @f = f
    @record = @f ? @f.object : nil
    @preview_path = preview_path
    @share_preview = share_preview
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
                          collapsed: true,
                          settings: false,
                          autosave_enabled: (@record && @record.try(:folio_autosave_enabled?)) || false,
                          autosave_timer: -1,
                        },
                        action: {
                          "message@window" => "onWindowMessage",
                          "change@document" => "onDocumentChange",
                          "input@document" => "onDocumentInput",
                          "focusin@document" => "onDocumentFocusin",
                          "focusout@document" => "onDocumentFocusout",
                          "folioConsoleCustomChange@document" => "onDocumentChange",
                          "fCPageReload" => "reloadPageWhenPossible",
                          "atomsFormHidden@document" => "onDocumentAtomsFormHidden",
                          "atomsFormShown@document" => "onDocumentAtomsFormShown",
                          "shown.bs.tab@document" => "onDocumentBsTabShown",
                          "submit@document" => "onDocumentSubmit",
                          "f-nested-fields:add@document" => "onNestedFieldsAdd",
                          "f-nested-fields:destroyed@document" => "onNestedFieldsDestroyed",
                          "f-c-form-footer:resumeAutosave" => "onResumeAutosave",
                          "f-c-form-footer:pauseAutosave" => "onPauseAutosave",
                        })
  end

  def saved_at_tooltip
    if @record && @record.created_at
      title = "#{t(".saved")} #{l(@record.updated_at, format: :console_short_with_seconds)}"
      stimulus_tooltip(title, placement: :right)
    end
  end

  def stimulus_action_unless_audit(hash)
    return nil if @audit
    stimulus_action(hash)
  end
end
