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
                          takeover_url: controller.takeover_revision_console_api_tiptap_revisions_path,
                          from_user_id: other_user.present? ? other_user.id : nil
                        })
  end

  def render?
    object.tiptap_autosave_enabled?
  end

  def has_unsaved_changes?
    object.has_tiptap_revision?
  end

  private
    def conflicted_revisions?
      current_user_latest_revision != object_latest_revision
    end

    def current_user_latest_revision
      @current_user_latest_revision ||= object.latest_tiptap_revision(user: Folio::Current.user)
    end

    def object_latest_revision
      @object_latest_revision ||= object.latest_tiptap_revision(user: nil)
    end

    def other_user
      conflicted_revisions? ? object_latest_revision.user : nil
    end

    def latest_revisions_info
      current_user_time_str = current_user_latest_revision.blank? ? t(".not_exists") : l(current_user_latest_revision.updated_at, format: :short)
      current_user_rev = t(".your_revision", time: current_user_time_str)
      other_user_rev = t(".other_user_revision", time: l(object_latest_revision.updated_at, format: :short), name: other_user.to_label)
      t(".latest_revisions", current_user_rev:, other_user_rev:)
    end
end
