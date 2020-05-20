# frozen_string_literal: true

class TestsController < ApplicationController
  def show
    render params.require(:view)
  end
end
