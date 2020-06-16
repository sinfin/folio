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

  def self.folio_console_controller_for(class_name, as: nil, except: [])
    klass = class_name.constantize

    if klass.private_method_defined?(:positionable_last_position)
      include Folio::Console::SetPositions
      handles_set_positions_for klass
    end

    respond_to :json, only: %i[update]

    load_and_authorize_resource(as, class: class_name,
                                    except: except,
                                    parent: (false if as.present?))

    before_action :add_record_breadcrumbs

    only = except.include?(:index) ? %i[merge] : %i[index merge]
    before_action only: only do
      name = folio_console_record_variable_name(plural: true)

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

    prepend_before_action except: (except + [:index]) do
      name = folio_console_record_variable_name(plural: false)

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
      add_breadcrumb '<i class="fa fa-home" style="min-width: 16px; min-height: 14px;"></i>'.html_safe, console_root_path
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

    def atoms_strong_params
      base = [:id,
              :type,
              :position,
              :placement_type,
              :_destroy,
              *file_placements_strong_params] + Folio::Atom.strong_params

      [{ atoms_attributes: base }] + I18n.available_locales.map do |locale|
        {
          "#{locale}_atoms_attributes": base
        }
      end
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

    def render_csv(records, class_name: nil, name: nil, separator: nil)
      klass = class_name ? class_name.constantize : @klass

      data = ::CSV.generate(headers: true) do |csv|
        csv << klass.csv_attribute_names.map do |a|
          klass.human_attribute_name(a)
        end
        records.each { |rec| csv << rec.csv_attributes }
      end

      name = name || klass.model_name.human(count: 2)

      filename = "#{name}-#{Date.today}.csv".split('.')
                                            .map(&:parameterize)
                                            .join('.')
      send_data data, filename: filename
    end

    def index_tabs
    end

    helper_method :index_tabs

    def add_record_breadcrumbs
      add_breadcrumb(@klass.model_name.human(count: 2),
                     url_for([:console, @klass]))

      if folio_console_record
        if folio_console_record.new_record?
          add_breadcrumb I18n.t('folio.console.breadcrumbs.actions.new')
        else
          add_breadcrumb(folio_console_record.to_label,
                         url_for([:edit, :console, folio_console_record]))
        end
      end
    rescue NoMethodError
    end
end
