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

  def changer_name
    object.latest_tiptap_revision&.user&.to_label
  end

  def latest_update_revision
    @latest_update_revision ||= object.latest_tiptap_revision
  end

  def current_user
    Folio::Current.user
  end

  def change_times
    {
      current: object.latest_tiptap_revision(user: current_user).updated_at,
      other: latest_update_revision.updated_at
    }
  end
end
