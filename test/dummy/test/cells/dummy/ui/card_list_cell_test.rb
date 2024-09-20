# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::CardListCellTest < Cell::TestCase
  test "show" do
    card_model = {
      title: "This is a section title",
      content: "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>",
      button_label: "Button label",
      href: "/folio/ui",
      cover_placement: create(:folio_cover_placement),
    }

    %i[large medium small].each do |size|
      model = [
        %i[cover_placement content title],
        %i[cover_placement content],
        %i[cover_placement title],
        %i[cover_placement],
        %i[content title],
        %i[content],
        %i[title],
        %i[],
      ].map do |keys|
        card_model.slice(*keys, :href, :button_label).merge(size => true)
      end

      html = cell("dummy/ui/card_list", model).(:show)
      assert html.has_css?(".d-ui-card-list")
    end
  end
end