# frozen_string_literal: true

class Dummy::Ui::CardListCell < ApplicationCell
  def show
    render if model.present?
  end
end
