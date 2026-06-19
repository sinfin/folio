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

  # The heartbeat must run even when the editor is alone in the record, so the
  # user does not silently expire out of the presence window.
  def test_renders_ping_controller_even_when_user_is_alone
    render_ping

    assert_selector(".f-c-current-users-presence-ping", visible: :all)
    assert_selector("[data-controller~='f-c-current-users-presence-ping']", visible: :all)
  end

  def test_wires_the_console_url_ping_endpoint
    render_ping

    assert_selector("[data-f-c-current-users-presence-ping-api-url-value*='console_url_ping']",
                    visible: :all)
  end

  def test_wires_a_canonical_presence_url
    render_ping

    assert_selector("[data-f-c-current-users-presence-ping-presence-url-value]", visible: :all)
  end

  # so the heartbeat can ask the server to render a warning bar for this record
  # and the first editor gets a live warning when a second editor arrives
  def test_signs_the_edited_record_into_a_placement_token
    page = create(:folio_page)

    with_controller_class(Folio::Console::BaseController) do
      with_request_url "/console/pages/#{page.id}/edit" do
        render_inline(Folio::Console::CurrentUsers::PresencePingComponent.new(record: page))
      end
    end

    attr = "data-f-c-current-users-presence-ping-placement-token-value"
    token_node = Nokogiri::HTML.fragment(rendered_content).at_css("[#{attr}]")
    assert token_node, "expected a placement token to be rendered"

    payload = Rails.application.message_verifier(
      Folio::Console::CurrentUsers::PresencePingComponent::PLACEMENT_VERIFIER_PURPOSE
    ).verify(token_node[attr])

    assert_equal "Folio::Page", payload["type"]
    assert_equal page.id, payload["id"]
  end

  def test_omits_placement_token_when_there_is_no_record
    render_ping

    assert_no_selector("[data-f-c-current-users-presence-ping-placement-token-value]", visible: :all)
  end

  private
    def render_ping
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/pages/1/edit" do
          render_inline(Folio::Console::CurrentUsers::PresencePingComponent.new)
        end
      end
    end
end
