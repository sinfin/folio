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
                          attribute_name: attribute_name,
                          delete_url: controller.delete_revision_console_api_tiptap_revisions_path,
                        })
  end

  def render?
    object.tiptap_autosave_enabled?
  end

  def has_unsaved_changes?
    object.has_tiptap_revision?(attribute_name: attribute_name)
  end

  private
    def latest_revision_info
      latest_revision = object.latest_tiptap_revision(user: Folio::Current.user, attribute_name: attribute_name)
      l(latest_revision.created_at, format: :short) if latest_revision
    end
end
