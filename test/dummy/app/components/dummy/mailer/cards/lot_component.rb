# frozen_string_literal: true

class Dummy::Mailer::Cards::LotComponent < Dummy::Mailer::BaseComponent
  THUMB_SIZE = "232x322#"

  def initialize(folio_image: nil,
                 author: nil,
                 name: nil,
                 event: nil,
                 description: nil,
                 id: nil,
                 auction_status: nil,
                 price: nil,
                 auction_date: nil,
                 limiting_end: nil,
                 button_label: nil,
                 button_href: nil)
    @folio_image = folio_image
    @author = author
    @name = name
    @event = event
    @description = description
    @id = id
    @auction_status = auction_status
    @price = price
    @auction_date = auction_date
    @limiting_end = limiting_end
    @button_label = button_label
    @button_href = button_href
  end

  def description
    @description.present? ? @description.values : nil
  end
end
