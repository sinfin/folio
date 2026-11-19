# frozen_string_literal: true

require "test_helper"

class Folio::Devise::ModalCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/modal", nil).(:show)
    assert html.has_css?(".f-devise-modal")
  end

  test "dialog is labelled for screen readers" do
    html = cell("folio/devise/modal", nil).(:show)

    assert html.has_css?('.f-devise-modal[role="dialog"][aria-modal="true"][aria-labelledby="f-devise-modal-title-sessions"]')
    assert html.has_css?("h2.modal-title#f-devise-modal-title-sessions")
    assert html.has_css?("h2.modal-title#f-devise-modal-title-registrations")
    assert html.has_css?('.f-devise-modal__close[aria-label="Close"]', count: 2)
  end
end
