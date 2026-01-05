# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeroComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::HeroComponent.new(title: "foo"))

    assert_selector(".d-ui-hero")

    # All parameters
    render_inline(Dummy::Ui::HeroComponent.new(title: "foo",
                                               perex: "bar",
                                               date: Time.current,
                                               cover: create(:folio_file_placement_cover),
                                               background_cover: create(:folio_file_placement_cover),
                                               image_size: :container,
                                               theme: :light,
                                               background_overlay: :light,
                                               background_color: "#000",
                                               show_divider: true))

    assert_selector(".d-ui-hero")

    # Disallowed parameter
    assert_raises(ArgumentError) do
      render_inline(Dummy::Ui::HeroComponent.new(title: "foo", image_size: "wrong"))
    end
  end
end
