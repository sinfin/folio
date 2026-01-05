# frozen_string_literal: true

class Folio::Console::Form::FooterComponent < Folio::Console::ApplicationComponent
  bem_class_name :static

  def initialize(f: nil,
                 preview_path: nil,
                 share_preview: false,
                 show_settings: true,
                 static: false,
                 submit_label: nil,
                 disable_modifications: false)
    @f = f
    @preview_path = preview_path
    @share_preview = share_preview
    @show_settings = show_settings
    @static = static
    @submit_label = submit_label
    @disable_modifications = disable_modifications
  end

  private
    def before_render
      # use audited_record as the revision might have changed audited_console_restorable? (i.e. swap published boolean)
      @record = controller.instance_variable_get(:@audited_record) || (@f ? @f.object : nil)
      @record ||= @f ? @f.object : nil

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

    def status
      return "saved" if @audit
      return "saved" unless @record

      if !controller.request.get? && @record.changed?
        "unsaved"
      else
        "saved"
      end
    end

    def data
      stimulus_controller("f-c-form-footer",
                          values: {
                            status:,
                            collapsed: true,
                            settings: false,
                            autosave_enabled: (@record && @record.try(:folio_autosave_enabled?)) || false,
                            autosave_paused: false,
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
                            "atomsFormShown@document" => "onDocumentAtomsFormShown",
                            "shown.bs.tab@document" => "onDocumentBsTabShown",
                            "submit@document" => "onDocumentSubmit",
                            "f-nested-fields:added@document" => "onNestedFieldsAdded",
                            "f-nested-fields:destroyed@document" => "onNestedFieldsDestroyed",
                            "f-input-collection-remote-select:open@document" => "onSelect2Open",
                            "f-input-collection-remote-select:close@document" => "onSelect2Close",
                            "f-modal:opened@document" => "onModalOpened",
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

    def read_only?
      @audit || @disable_modifications
    end

    def stimulus_action_unless_readonly(hash)
      return nil if read_only?
      stimulus_action(hash)
    end
end
