# frozen_string_literal: true

class Dummy::Ui::DisclaimerComponent < ApplicationComponent
  def initialize(page: nil)
    @page = page
  end

  def text
    if @page
      link = link_to(t(".link"), url_for(@page))
    else
      link = t(".link")
    end

    t(".text", link:).html_safe
  end
end
