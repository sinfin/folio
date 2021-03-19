# frozen_string_literal: true

class Folio::UiCell < Folio::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def show
    if model.present?
      @mobile_only = true
      render(:_typo)
    else
      render
    end
  end

  def main_colors
    %w[blue primary]
  end

  def additional_colors
    %w[light-gray medium-gray gray dark-gray blue red purple green orange yellow]
  end

  def button_variants
    %w[primary secondary]
  end

  def button_sizes
    [nil, "btn-sm", "btn-lg"]
  end
end
