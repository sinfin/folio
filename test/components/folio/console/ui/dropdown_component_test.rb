# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::DropdownComponentTest < Folio::Console::ComponentTest
  def test_render
    links = [
      { label: "First tab", href: "#1" },
      { label: "Second tab", href: "#2" },
      { label: "Third tab", href: "#3", icon: :archive },
    ]

    render_inline(Folio::Console::Ui::DropdownComponent.new(links:))

    assert_selector(".f-c-ui-dropdown")
  end

  def test_render_with_disabled_links
    links = [
      { label: "First tab", href: "#1" },
      { label: "Second tab", href: "#2", disabled: true },
      { label: "Third tab", href: "#3", icon: :archive },
    ]

    render_inline(Folio::Console::Ui::DropdownComponent.new(links:))

    assert_selector(".f-c-ui-dropdown")
    assert_selector(".dropdown-item.f-c-index-actions__link--disabled", text: "Second tab")
  end
end
