# frozen_string_literal: true

class Dummy::Atom::NavigationCell < ApplicationCell
  def show
    render if model && model.menu
  end
end
