# frozen_string_literal: true

class Folio::UiCell < Folio::ApplicationCell
  def main_colors
    %w[blue primary]
  end

  def additional_colors
    %w[light-gray medium-gray gray dark-gray blue red purple green orange yellow]
  end
end
