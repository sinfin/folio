# frozen_string_literal: true

class Dummy::Ui::ArticleCardListCell < ApplicationCell
  def show
    render if model.present?
  end
end
