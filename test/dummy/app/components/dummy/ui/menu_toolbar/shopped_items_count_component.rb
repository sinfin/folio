# frozen_string_literal: true

class Dummy::Ui::MenuToolbar::ShoppedItemsCountComponent < ApplicationComponent
  def initialize(class_name: nil, wishlist: false)
    @class_name = class_name
    @wishlist = wishlist
  end

  def count
    @wishlist ? "345" : "5"
  end
end
