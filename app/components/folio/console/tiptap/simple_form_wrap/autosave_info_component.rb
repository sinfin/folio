# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrap::AutosaveInfoComponent < Folio::Console::ApplicationComponent
  attr_reader :object, :attribute_name

  def initialize(object:, attribute_name: nil)
    @object = object
    @attribute_name = attribute_name || "tiptap_content"
  end

  def data
    stimulus_controller("f-c-tiptap-simple-form-wrap-autosave-info",
                        values: {
                          placement_type: object.class.base_class.name,
                          placement_id: object.id,
                          takeover_url: controller.takeover_revision_console_api_tiptap_revisions_path,
                          from_user_id: other_user.present? ? other_user.id : nil,
                          attribute_name:,
                        })
  end

  def render?
    object.try(:tiptap_autosave_enabled?, attribute_name:)
  end

  def has_own_unsaved_changes?
    object.has_tiptap_revision?(attribute_name:, user: Folio::Current.user)
  end

  private
    def conflicted_revisions?
      if current_user_latest_revision.nil?
        object_latest_revision && object.updated_at < object_latest_revision.updated_at
      else
        current_user_latest_revision != object_latest_revision
      end
    end

    def outdated_revision?
      current_user_latest_revision && current_user_latest_revision.updated_at < object.updated_at
    end

    def updated_by_user
      current_user_latest_revision&.superseded_by_user
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
