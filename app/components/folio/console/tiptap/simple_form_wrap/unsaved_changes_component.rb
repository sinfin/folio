# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrap::UnsavedChangesComponent < Folio::Console::ApplicationComponent
  attr_reader :object

  def initialize(object:)
    @object = object
  end

  def data
    stimulus_controller("f-c-tiptap-simple-form-wrap-unsaved-changes")
  end

  private
    def latest_revision_info
      latest_revision = object.latest_tiptap_revision(user: Folio::Current.user)
      "#{l(latest_revision.created_at, format: :short)} – #{latest_revision.user.full_name}"
    end
end
