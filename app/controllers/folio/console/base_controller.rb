# frozen_string_literal: true

require 'csv'

class Folio::Console::BaseController < Folio::ApplicationController
  include Pagy::Backend
  include Folio::Console::DefaultActions
  include Folio::Console::Includes

  before_action :authenticate_account!
  before_action :add_root_breadcrumb
  before_action do
    I18n.locale = Rails.application.config.folio_console_locale
  end
  # TODO: before_action :authorize_account!

  layout 'folio/console/application'
  self.responder = Folio::Console::ApplicationResponder
  respond_to :html
  respond_to :json, only: %i[update]

  TYPE_ID_DELIMITER = ' -=- '

  # rescue_from CanCan::AccessDenied do |exception|
  #   redirect_to dashboard_path, alert: exception.message
  # end

  def self.folio_console_controller_for(class_name)
    klass = class_name.constantize

    if klass.private_method_defined?(:positionable_last_position)
      include Folio::Console::SetPositions
      handles_set_positions_for klass
    end

    respond_to :json, only: %i[update]

    load_and_authorize_resource(class: class_name)

    before_action do
      begin
        add_breadcrumb(klass.model_name.human(count: 2),
                       url_for([:console, klass]))
      rescue NoMethodError
      end
    end

    before_action only: :index do
      name = "@#{params[:controller].split('/').last}".to_sym

      if folio_console_collection_includes.present?
        with_include = instance_variable_get(name).includes(*folio_console_collection_includes)
        instance_variable_set(name, with_include)
      end

      if filter_params.present? &&
         instance_variable_get(name).respond_to?(:filter_by_params)
        filtered = instance_variable_get(name).filter_by_params(filter_params)
        instance_variable_set(name, filtered)
      end
    end

    prepend_before_action except: :index do
      name = "@#{params[:controller].split('/').last.singularize}".to_sym

      if folio_console_record_includes.present?
        begin
          instance_variable_set(name, klass.includes(*folio_console_record_includes)
                                           .find(params[:id]))
        rescue ActiveRecord::RecordNotFound
        end
      end
    end

    prepend_before_action do
      @klass = klass
    end
  end

  def url_for(options = nil)
    super(options)
  rescue NoMethodError
    main_app.url_for(options)
  end

  def filter_params
    params.permit(:by_query, *index_filters.keys)
  end

  private
    # TODO: authorize account
    # def authorize_admin_user!
    #   authorize! :manage, :all
    # end

    def index_filters
      {}
    end

    def current_ability
      @current_ability ||= Folio::ConsoleAbility.new(current_account)
    end

    def add_root_breadcrumb
      add_breadcrumb '<i class="fa fa-home"></i>'.html_safe, console_root_path
    end

    def additional_file_placements_strong_params_keys
      []
    end

    def additional_private_attachments_strong_params_keys
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

    def private_attachments_strong_params
      commons = %i[id title alt file type _destroy]
      hash = { private_attachments_attributes: commons }

      additional_private_attachments_strong_params_keys.each do |key|
        hash[key] = commons
      end

      [ hash ]
    end

    def basic_atoms_strong_params
      [
        {
          atoms_attributes: [:id,
                             :title,
                             :perex,
                             :content,
                             :type,
                             :model,
                             :model_id,
                             :model_type,
                             :position,
                             :_destroy,
                             *file_placements_strong_params]
        }
      ]
    end

    def atoms_strong_params
      base = [:id,
              :title,
              :perex,
              :content,
              :type,
              :model,
              :model_id,
              :model_type,
              :position,
              :_destroy,
              *file_placements_strong_params]

      [{ atoms_attributes: base }] + I18n.available_locales.map do |locale|
        {
          "#{locale}_atoms_attributes": base
        }
      end
    end

    def sti_atoms(params)
      keys = I18n.available_locales.map do |locale|
        "#{locale}_atoms_attributes"
      end + ['atoms_attributes']

      keys.reduce(params) do |pars, key|
        sti_hack(pars, key.to_sym, :model)
      end
    end

    def params_with_atoms(params)
      sti_atoms(params)
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

    # Override respond_with to redirect to :index by default
    def respond_with(*resources, &block)
      options = resources.size == 1 ? {} : resources.extract_options!
      if options[:action].nil? && options[:location].nil?
        if resources.size == 1 &&
           !resources.first.try(:destroyed?) &&
           resources.first.try(:persisted?)
          referrer = request.referer.try(:gsub, '/new', '')
          options[:location] ||= (referrer || url_for([:console,
                                                       resources.first,
                                                       action: :edit]))
        else
          options[:location] ||= url_for([:console, @klass])
        end
      end

      if resources.size == 1
        super(resources.first, options, &block)
      else
        super(*resources, &block)
      end
    end

    def render_csv(records)
      data = ::CSV.generate(headers: true) do |csv|
        csv << @klass.csv_attribute_names.map do |a|
          @klass.human_attribute_name(a)
        end
        records.each { |rec| csv << rec.csv_attributes }
      end
      name = @klass.model_name.human(count: 2)
      filename = "#{name}-#{Date.today}.csv".split('.')
                                            .map(&:parameterize)
                                            .join('.')
      send_data data, filename: filename
    end
end
