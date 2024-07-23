# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::OrderSummaryComponentTest < Folio::ComponentTest
  def test_render
    items = [
              { title: "Beulah Erickson", subtitle: "Item 1", total_price: "10 000 000", comission: "15,700", count: 2, folio_image: Folio::File::Image.first },
              { title: "František Kupka", subtitle: "Item 2", total_price: "10 000 000", comission: "15,000", count: 2, folio_image: Folio::File::Image.first },
              { title: "Josef Velčovský", subtitle: "Item 3", total_price: "10 000 000", comission: "15,000", count: 2, folio_image: Folio::File::Image.first },
            ]

    render_inline(Dummy::Mailer::OrderSummaryComponent.new(items:))

    assert_selector(".d-mailer-order-summary")
  end
end
