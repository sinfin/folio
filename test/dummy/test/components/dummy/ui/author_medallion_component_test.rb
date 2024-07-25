# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::AuthorMedallionComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::AuthorMedallionComponent.new(name: "foo", href: "#", cover: nil))

    assert_selector(".d-ui-author-medallion")
  end
end
