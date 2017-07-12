# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Console::BaseController < ApplicationController
    before_action :authenticate_account!
    #TODO: before_action :authorize_account!

    layout 'folio/console/application'

    # rescue_from CanCan::AccessDenied do |exception|
    #   redirect_to dashboard_path, alert: exception.message
    # end

    def index
      redirect_to console_dashboard_path
    end

    private

      def set_locale
        I18n.locale = :cs
      end

      # TODO: authorize account
      # def authorize_admin_user!
      #   authorize! :manage, :all
      # end
      #
      # def current_ability
      #   @ability ||= Ability.new(current_admin)
      # end

      def current_admin
        current_account
      end

      helper_method :current_admin

      def query
        @query ||= params[:by_query]
      end

      helper_method :query

      def sidebar_size
        3
      end

      helper_method :sidebar_size

      def current_page
        params.permit(:page)[:page].to_i || 1
      end
  end
end
