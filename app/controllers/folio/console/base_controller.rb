# frozen_string_literal: true

module Folio
  class Console::BaseController < ApplicationController
    before_action :authenticate_account!
    before_action :add_root_breadcrumb
    # TODO: before_action :authorize_account!

    layout 'folio/console/application'
    self.responder = Console::ApplicationResponder
    respond_to :html
    respond_to :json, only: %i[update]

    TYPE_ID_DELIMITER = ' -=- '

    # rescue_from CanCan::AccessDenied do |exception|
    #   redirect_to dashboard_path, alert: exception.message
    # end

    def index
      redirect_to console_dashboard_path
    end

    private
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

      def file_placements_strong_params
        commons = [:id,
                   :caption,
                   :tag_list,
                   :file_id,
                   :position,
                   :type,
                   :_destroy]

        [{
          cover_placement_attributes: commons,
          document_placements_attributes: commons,
          image_placements_attributes: commons,
        }]
      end

      def atoms_strong_params
        [{
          atoms_attributes: [:id,
                             :type,
                             :model,
                             :model_id,
                             :model_type,
                             :title,
                             :content,
                             :perex,
                             :position,
                             :_destroy,
                             *cover_placement_strong_params,
                             *file_placements_strong_params]
        }]
      end

      def additional_strong_params(node)
        if node.class == NodeTranslation
          node.node_original.additional_params
        else
          node.additional_params
        end
      end

      def sti_atoms(params)
        sti_hack(params, :atoms_attributes, :model)
      end

      def sti_hack(params, nested_name, relation_name)
        params.tap do |obj|
          # STI hack
          if obj[nested_name]
            relation_type = "#{relation_name}_type".to_sym
            relation_id = "#{relation_name}_id".to_sym

            obj[nested_name].each do |key, value|
              next if value[relation_name].nil?
              type, id = value[relation_name].split(TYPE_ID_DELIMITER)
              obj[nested_name][key][relation_type] = type
              obj[nested_name][key][relation_id] = id
              obj[nested_name][key].delete(relation_name)
            end
          end

          obj
        end
      end
  end
end
