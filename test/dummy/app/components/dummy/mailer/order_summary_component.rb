# frozen_string_literal: true

class Dummy::Mailer::OrderSummaryComponent < Dummy::Mailer::BaseComponent
  THUMB_SIZE = "70x70"

  def initialize(title: nil, items:, total: nil, status: nil)
    @title = title
    @items = items
    @total = total
    @status = status
  end

  def render?
    @items.present?
  end
end
