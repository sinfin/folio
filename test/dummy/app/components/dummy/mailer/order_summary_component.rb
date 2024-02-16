# frozen_string_literal: true

class Dummy::Mailer::OrderSummaryComponent < ApplicationComponent
  THUMB_SIZE = "70x70#"

  def initialize(title: nil, items: nil, total: nil, status: nil)
    @title = title
    @items = items
    @total = total
    @status = status
  end
end
