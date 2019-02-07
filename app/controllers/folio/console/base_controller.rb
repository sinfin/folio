# frozen_string_literal: true

class Folio::Console::BaseController < Folio::ApplicationController
  include Pagy::Backend

  before_action :authenticate_account!
  before_action :add_root_breadcrumb
  # TODO: before_action :authorize_account!

  layout 'folio/console/application'
  self.responder = Folio::Console::ApplicationResponder
  respond_to :html
  respond_to :json, only: %i[update]

  TYPE_ID_DELIMITER = ' -=- '

  # rescue_from CanCan::AccessDenied do |exception|
  #   redirect_to dashboard_path, alert: exception.message
  # end

  def index
    redirect_to console_dashboard_path
  end

  def self.folio_console_controller_for(class_name)
    klass = class_name.safe_constantize

    if klass.private_method_defined?(:positionable_last_position)
      include Folio::Console::SetPositions
      handles_set_positions_for klass
    end

    respond_to :json, only: %i[update]

    load_and_authorize_resource(class: class_name)

    before_action do
      @klass = klass

      add_breadcrumb(klass.model_name.human(count: 2),
                     url_for([:console, klass]))
    end
  end

  private
    # TODO: authorize account
    # def authorize_admin_user!
    #   authorize! :manage, :all
    # end

    def current_ability
      @current_ability ||= Folio::ConsoleAbility.new(current_admin)
    end

    def query
      @query ||= params[:by_query]
    end

    helper_method :query

    def filter_params
      params.permit(:by_query, *index_filters.keys)
    end

    def index_filters
      {}
    end

    helper_method :filter_params
    helper_method :index_filters

    def add_root_breadcrumb
      add_breadcrumb '<i class="fa fa-home"></i>'.html_safe, console_root_path
    end

    def additional_file_placements_strong_params_keys
      []
    end

    def file_placements_strong_params
      commons = [:id,
                 :title,
                 :alt,
                 :tag_list,
                 :file_id,
                 :position,
                 :type,
                 :_destroy]

      hash = {}

      (additional_file_placements_strong_params_keys + %i[
        cover_placement_attributes
        document_placement_attributes
        document_placements_attributes
        image_placements_attributes
      ]).each do |key|
        hash[key] = commons
      end

      [ hash ]
    end

    def atoms_strong_params
      [{
        atoms_attributes: [:id,
                           :type,
                           :model,
                           :model_id,
                           :model_type,
                           :position,
                           :_destroy,
                           *Folio::Atom.text_fields,
                           *file_placements_strong_params]
      }]
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
