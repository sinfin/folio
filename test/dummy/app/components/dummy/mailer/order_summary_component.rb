# frozen_string_literal: true

class Dummy::Mailer::OrderSummaryComponent < Dummy::Mailer::BaseComponent
  include Folio::PriceHelper

  THUMB_SIZE = "70x70"

  def initialize(title: nil, items:, total: nil, invoice_url: nil)
    @title = title
    @items = items
    @total = total
    @invoice_url = invoice_url
  end

  def render?
    @items.present?
  end

  def invoice_text
    link = link_to(t(".invoice_text_link"),
                   @invoice_url,
                   class: "d-mailer-order-summary__payment-regulation-link",
                   style: "font-weight: 400;")

    t(".invoice_text", link:).html_safe
  end
end
