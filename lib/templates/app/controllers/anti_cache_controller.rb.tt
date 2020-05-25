# frozen_string_literal: true

class AntiCacheController < ApplicationController
  def show
    case params['name']
    when :foo
      render plain: 'bar'
    else
      head 400
    end
  end

  private

    def render_cell(name)
      render plain: cell(name).show
    end
end
