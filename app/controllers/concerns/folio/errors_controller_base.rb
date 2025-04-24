# frozen_string_literal: true

module Folio::ErrorsControllerBase
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_control_no_store
  end

  def page400
    @error_code = 400
    render_errors_show
  end

  def page403
    @error_code = 403
    render_errors_show
  end

  def page404
    @error_code = 404
    render_errors_show
  end

  def page422
    @error_code = 422
    render_errors_show
  end

  def page500
    @error_code = 500
    render_errors_show
  end

  private
    def render_errors_show
      if request.original_fullpath.start_with?("/console") && !self.is_a?(Folio::Console::BaseController)
        controller = Folio::Console::BaseController.new
        controller.request = request
        controller.response = response

        render plain: controller.process(action_name)
      else
        render "folio/errors/show", status: @error_code
      end
    end

    def set_cache_control_no_store
      no_store
    end
end
