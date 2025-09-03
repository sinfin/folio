# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrap::AutosaveInfoComponent < Folio::Console::ApplicationComponent
  attr_reader :object

  def initialize(object:)
    @object = object
  end

  def data
    stimulus_controller("f-c-tiptap-simple-form-wrap-autosave-info",
                        values: {
                          placement_type: object.class.base_class.name,
                          placement_id: object.id,
                          delete_url: helpers.delete_revision_console_api_tiptap_revisions_path,
                        })
  end

  def render?
    tiptap_autosave_enabled?
  end

  def tiptap_autosave_enabled?
    config = object.try(:tiptap_config) || Folio::Tiptap.config
    config&.autosave == true
  end

  def has_unsaved_changes?
    object.has_tiptap_revision?
  end

  private
    def latest_revision_info
      latest_revision = object.latest_tiptap_revision(user: Folio::Current.user)
      l(latest_revision.created_at, format: :short)
    end
end
