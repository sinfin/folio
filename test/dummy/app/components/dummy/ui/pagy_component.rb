# frozen_string_literal: true

class Dummy::Ui::PagyComponent < ApplicationComponent
  include Pagy::Frontend

  def initialize(pagy:)
    @pagy = pagy
  end

  def link
    @link ||= pagy_link_proc(@pagy)
  end
end
