# frozen_string_literal: true

module Folio
  class Console::BaseController < ApplicationController
    before_action :authenticate_account!
    before_action :add_root_breadcrumb
    # TODO: before_action :authorize_account!

    layout 'folio/console/application'
    self.responder = Console::ApplicationResponder
    respond_to :html

    # rescue_from CanCan::AccessDenied do |exception|
    #   redirect_to dashboard_path, alert: exception.message
    # end

    def index
      redirect_to console_dashboard_path
    end

    private

      def set_locale
        I18n.locale = :en
      end

      # TODO: authorize account
      # def authorize_admin_user!
      #   authorize! :manage, :all
      # end

      def current_ability
        @current_ability ||= ConsoleAbility.new(current_admin)
      end

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

      def filter_params
        params.permit(:by_query)
      end

      helper_method :filter_params

      def add_root_breadcrumb
        add_breadcrumb '<i class="fa fa-home"></i>'.html_safe, console_root_path
      end

      def cover_placement_strong_params
        [{
          cover_placement_attributes: [:id,
                                       :file_id,
                                       :_destroy]

        }]
      end

      def file_placements_strong_params
        [{
          file_placements_attributes: [:id,
                                       :caption,
                                       :tag_list,
                                       :file_id,
                                       :position,
                                       :_destroy]

        }]
      end

      def atoms_strong_params
        [{
          atoms_attributes: [:id,
                             :type,
                             :model_id,
                             :model_type,
                             :title,
                             :content,
                             :position,
                             :_destroy,
                             *cover_placement_strong_params,
                             *file_placements_strong_params]
        }]
      end

      def additional_strong_params(node)
        if node.class == Folio::NodeTranslation
          node.node_original.additional_params
        else
          node.additional_params
        end
      end
  end
end
