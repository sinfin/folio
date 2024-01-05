# frozen_string_literal: true

class Dummy::Ui::TabsComponent < ApplicationComponent

  def initialize(tabs: nil)
    @tabs = tabs
  end

  def render?
    @tabs.present?
  end
end
