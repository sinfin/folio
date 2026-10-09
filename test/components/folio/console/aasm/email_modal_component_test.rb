# frozen_string_literal: true

require "test_helper"

class Folio::Console::Aasm::EmailModalComponentTest < Folio::Console::ComponentTest
  def test_render
    render_modal

    assert_selector(".f-c-aasm-email-modal", visible: :all)
  end

  def test_form_posts_to_the_aasm_event_endpoint
    render_modal

    assert_selector(".f-c-aasm-email-modal__form[action='/console/api/aasm/event']", visible: :all)
  end

  def test_carries_the_fields_the_endpoint_reads
    render_modal

    assert_selector("input[name='event_email_enabled']", visible: :all)
    assert_selector("input[name='event_email_subject']", visible: :all)
    assert_selector("textarea[name='event_email_text']", visible: :all)

    %w[klass aasm_event id email].each do |key|
      assert_selector("input[type='hidden'][name='#{key}'][data-f-c-aasm-email-modal-target='hidden']", visible: :all)
    end
  end

  def test_wires_stimulus_controller_actions_and_targets
    render_modal

    assert_selector(".f-c-aasm-email-modal[data-controller*='f-c-aasm-email-modal']", visible: :all)
    assert_selector(".f-c-aasm-email-modal[data-action*='folioConsoleAasmEmailModalOpen->f-c-aasm-email-modal#openFromEvent']", visible: :all)
    assert_selector("[data-f-c-aasm-email-modal-target='title']", visible: :all)
    assert_selector("[data-f-c-aasm-email-modal-target='checkbox']", visible: :all)
    assert_selector("[data-f-c-aasm-email-modal-target='checkboxLabel']", visible: :all)
    assert_selector("[data-f-c-aasm-email-modal-target='subject']", visible: :all)
    assert_selector("[data-f-c-aasm-email-modal-target='text']", visible: :all)
    assert_selector("[data-f-c-aasm-email-modal-target='submit']", visible: :all)
  end

  def test_cancel_closes_folio_modal
    render_modal

    assert_selector("button[type='button'][data-controller*='f-modal-close']", visible: :all)
  end

  def test_uses_component_i18n_keys
    I18n.with_locale(:en) do
      render_modal

      assert_selector(".f-c-aasm-email-modal[data-f-c-aasm-email-modal-title-value*='{STATE_NAME}']", visible: :all)
      assert_selector(".f-c-aasm-email-modal[data-f-c-aasm-email-modal-send-email-label-value*='{EMAIL}']", visible: :all)
      assert_selector("input[placeholder='E-mail subject']", visible: :all)
      assert_selector("textarea[placeholder='E-mail content']", visible: :all)
    end
  end

  private
    def render_modal
      with_controller_class(Folio::Console::PagesController) do
        with_request_url "/console" do
          render_inline(Folio::Console::Aasm::EmailModalComponent.new)
        end
      end
    end
end
