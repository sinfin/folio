# frozen_string_literal: true

require "test_helper"

class Folio::Console::CurrentUsers::PresencePingComponentTest < Folio::Console::ComponentTest
  def setup
    super
    @superadmin = create(:folio_user, :superadmin)
    Folio::Current.user = @superadmin
    Folio::Current.reset_ability!
  end

  def teardown
    Folio::Current.user = nil
    super
  end

  def test_renders_ping_controller_even_when_user_is_alone
    render_ping(create(:folio_page))
    assert_selector(".f-c-current-users-presence-ping", visible: :all)
    assert_selector("[data-controller~='f-c-current-users-presence-ping']", visible: :all)
  end

  def test_sends_the_edited_record_identity
    page = create(:folio_page)
    render_ping(page)

    assert_selector("[data-f-c-current-users-presence-ping-record-type-value='#{page.class.base_class.name}']",
                    visible: :all)
    assert_selector("[data-f-c-current-users-presence-ping-record-id-value='#{page.id}']",
                    visible: :all)
  end

  def test_wires_the_ping_and_clear_endpoints
    render_ping(create(:folio_page))
    assert_selector("[data-f-c-current-users-presence-ping-api-url-value*='console_presence_ping']",
                    visible: :all)
  end

  private
    def render_ping(record)
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/pages/#{record.id}/edit" do
          render_inline(Folio::Console::CurrentUsers::PresencePingComponent.new(record:))
        end
      end
    end
end
