# frozen_string_literal: true

class Dummy::Ui::TabsCell < ApplicationCell
  def show
    render if model.present?
  end
end
