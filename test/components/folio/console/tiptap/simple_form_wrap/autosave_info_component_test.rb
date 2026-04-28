# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::SimpleFormWrap::AutosaveInfoComponentTest < Folio::Console::ComponentTest
  COMPONENT_CLASS = Folio::Console::Tiptap::SimpleFormWrap::AutosaveInfoComponent

  def setup
    super
    Folio::Current.user = nil
    @page = create(:folio_page)
    @current_user = create(:folio_user, :superadmin)
  end

  def teardown
    Folio::Current.user = nil
    super
  end

  def test_render_handles_nil_updated_by_user
    create_revision(user: @current_user, content: "current", updated_at: 2.hours.ago)

    I18n.with_locale(:en) do
      render_component

      assert_text("An unknown user saved a new version of the content in the meantime.")
    end
  end

  def test_render_handles_nil_other_user
    @page.update_column(:updated_at, 3.hours.ago)
    create_revision(user: @current_user, content: "current", updated_at: 2.hours.ago)
    create_revision(user: nil, content: "other", updated_at: 1.hour.ago)

    I18n.with_locale(:en) do
      render_component

      assert_text("An unknown user also added unsaved draft changes in the meantime.")
      assert_text("(unknown user)")
    end
  end

  private
    def create_revision(user:, content:, updated_at:)
      @page.tiptap_revisions.create!(
        user:,
        attribute_name: "tiptap_content",
        content: { "content" => content },
        created_at: updated_at,
        updated_at:
      )
    end

    def render_component
      Folio::Current.user = @current_user

      with_controller_class(Folio::Console::PagesController) do
        with_request_url "/console/pages/#{@page.id}/edit" do
          render_inline(COMPONENT_CLASS.new(object: @page))
        end
      end
    end
end
