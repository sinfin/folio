# frozen_string_literal: true

class Dummy::Ui::TabsComponent < ApplicationComponent

  def initialize(tabs: nil)
    @tabs = tabs
  end

  def show
    render if tabs.present?
  end
end
