# frozen_string_literal: true

require "test_helper"

class Folio::Devise::ModalCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/modal", nil).(:show)
    assert html.has_css?(".f-devise-modal")
  end
end
