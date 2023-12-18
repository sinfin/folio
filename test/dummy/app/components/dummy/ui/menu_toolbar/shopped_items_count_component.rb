# frozen_string_literal: true

class Dummy::Ui::MenuToolbar::ShoppedItemsCountComponent < ApplicationComponent
  def initialize(class_name: nil)
    @class_name = class_name
  end

  def count
    "5"
  end
end
