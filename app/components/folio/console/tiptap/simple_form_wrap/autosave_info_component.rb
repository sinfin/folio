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
                          delete_url: controller.delete_revision_console_api_tiptap_revisions_path,
                        })
  end

  def render?
    object.tiptap_autosave_enabled?
  end

  def has_own_unsaved_changes?
    object.has_tiptap_revision?(user: current_user)
  end

  def is_colliding_with_other_user?
    has_own_unsaved_changes? && latest_update_revision.user_id != current_user.id
  end

  private
    def latest_revision_info
      latest_revision = object.latest_tiptap_revision(user: Folio::Current.user)
      l(latest_revision.created_at, format: :short)
    end
end
