# frozen_string_literal: true

require "csv"

class Folio::Console::BaseController < Folio::ApplicationController
  include Folio::Console::DefaultActions
  include Folio::Console::Includes
  include Folio::HasCurrentSite
  include Pagy::Backend

  before_action :custom_authenticate_account!

  before_action :add_root_breadcrumb

  before_action do
    if (params[:rmp] && account_signed_in?) || ENV["FORCE_MINI_PROFILER"]
      Rack::MiniProfiler.authorize_request
    end
  end

  layout "folio/console/application"
  self.responder = Folio::Console::ApplicationResponder
  respond_to :html
  respond_to :json, only: %i[update]

  TYPE_ID_DELIMITER = " -=- "

  # rescue_from CanCan::AccessDenied do |exception|
  #   redirect_to dashboard_path, alert: exception.message
  # end

  def self.folio_console_controller_for(class_name, as: nil, except: [], csv: false, catalogue_collection_actions: nil, through: nil)
    as_s = as.present? ? as.to_s : nil

    define_method :folio_console_controller_for_as do
      as_s
    end

    define_method :folio_console_controller_for_through do
      through
    end

    define_method :folio_console_controller_for_handle_csv do
      csv
    end

    define_method :folio_console_controller_for_catalogue_collection_actions do
      catalogue_collection_actions
    end

    klass = class_name.constantize

    if klass.private_method_defined?(:positionable_last_position)
      include Folio::Console::SetPositions
      handles_set_positions_for klass
    end

    if klass.method_defined?(:revisions)
      before_action :load_revisions, only: [klass.audited_view_name, :revision]
      before_action :find_revision, only: [:revision, :restore]
    end

    respond_to :json, only: %i[update]

    # keep this above load_and_authorize_resource
    if klass.try(:has_belongs_to_site?)
      before_action :load_belongs_to_site_resource
    end

    if through
      through_as = through.demodulize.underscore

      load_and_authorize_resource(through_as, class: through)

      load_and_authorize_resource(as, class: class_name,
                                      except:,
                                      parent: (false if as.present?),
                                      through: through_as)
    else
      load_and_authorize_resource(as, class: class_name,
                                      except:,
                                      parent: (false if as.present?))
    end

    # keep this under load_and_authorize_resource
    if klass.try(:has_belongs_to_site?)
      before_action :filter_records_by_belongs_to_site
    end

    before_action :add_through_breadcrumbs
    before_action :add_collection_breadcrumbs
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

      if params[:sort].present?
        # sort_*_asc or sort_*_desc
        sort = params[:sort].to_s
        scope_name = "sort_by_#{sort}"

        if instance_variable_get(name).respond_to?(scope_name)
          @sorted_by_param = scope_name
          sorted = instance_variable_get(name).send(scope_name)
          instance_variable_set(name, sorted)
        else
          @sorted_by_param = nil
        end
      end

      if params[:sort].
         instance_variable_get(name).respond_to?(:sort_by_params)
        filtered = instance_variable_get(name).filter_by_params(filter_params)
        instance_variable_set(name, filtered)
      end
    end

    prepend_before_action except: (except + [:index]) do
      name = folio_console_record_variable_name(plural: false)

      if folio_console_record_includes.present?
        begin
          scope = klass.includes(*folio_console_record_includes)
          scope = scope.friendly if scope.respond_to?(:friendly)
          instance_variable_set(name, scope.find(params[:id]))
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
      commons = %i[id title alt file type position _destroy]
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

    def console_notes_strong_params
      [
        {
          console_notes_attributes: %i[id
                                       position
                                       content
                                       closed_at
                                       due_at
                                       closed_by_id
                                       created_by_id
                                       _destroy]
        }
      ]
    end

    def base_address_attributes
      %i[
        id
        _destroy
        name
        company_name
        address_line_1
        address_line_2
        zip
        city
        country_code
        state
        identification_number
        vat_identification_number
        phone
        email
        type
      ]
    end

    def addresses_strong_params
      [{ primary_address_attributes: base_address_attributes, secondary_address_attributes: base_address_attributes }]
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

    def render_csv(records, class_name: nil, name: nil, separator: ",")
      klass = class_name ? class_name.constantize : @klass

      data = ::CSV.generate(headers: true, col_sep: separator) do |csv|
        csv << klass.csv_attribute_names.map do |a|
          klass.human_attribute_name(a)
        end
        records.each { |rec| csv << rec.csv_attributes(self) }
      end

      name = name || klass.model_name.human(count: 2)

      filename = "#{name}-#{Date.today}.csv".split(".")
                                            .map(&:parameterize)
                                            .join(".")
      send_data data, filename:
    end

    def index_tabs
    end

    helper_method :index_tabs

    def load_revisions
      if folio_console_record && folio_console_record.respond_to?(:revisions)
        @audited_revisions = folio_console_record.revisions.reverse
      end
    end

    def find_revision
      audit = folio_console_record.audits.find_by_version!(params[:version])
      @audited_revision = audit.revision
      @audited_revision.audit = audit

      if @audited_revision.class.try(:has_audited_atoms?)
        @audited_revision.reconstruct_atoms
      end
    end

    def add_through_breadcrumbs
      return unless folio_console_controller_for_through
      through_klass = folio_console_controller_for_through.constantize

      add_breadcrumb(through_klass.model_name.human(count: 2),
                     url_for([:console, through_klass]))

      through_record = instance_variable_get("@#{through_klass.model_name.element}")

      if through_record
        add_breadcrumb(through_record.to_label, console_show_or_edit_path(through_record))
      end
    end

    def add_collection_breadcrumbs
      if folio_console_controller_for_through
        begin
          through_klass = folio_console_controller_for_through.constantize
          through_record = instance_variable_get("@#{through_klass.model_name.element}")

          add_breadcrumb(@klass.model_name.human(count: 2),
                         console_show_or_edit_path(through_record))
        rescue NoMethodError
          add_breadcrumb(@klass.model_name.human(count: 2))
        end
      else
        add_breadcrumb(@klass.model_name.human(count: 2),
                       url_for([:console, @klass]))
      end
    rescue NoMethodError
    end

    def add_record_breadcrumbs
      if folio_console_record
        if folio_console_record.new_record?
          add_breadcrumb I18n.t("folio.console.breadcrumbs.actions.new")
        else
          if folio_console_controller_for_through
            through_klass = folio_console_controller_for_through.constantize
            through_record = instance_variable_get("@#{through_klass.model_name.element}")

            record_url = console_show_or_edit_path(folio_console_record, through: through_record)
          else
            record_url = console_show_or_edit_path(folio_console_record)
          end

          add_breadcrumb(folio_console_record.to_label, record_url)
        end
      end
    rescue StandardError
      add_breadcrumb(folio_console_record.to_label)
    end

    def custom_authenticate_account!
      authenticate_account!
    end

    def console_show_or_edit_path(record, through: nil, other_params: {})
      return nil if record.nil?

      begin
        if through
          url = url_for([:console, through, record, other_params])
        else
          url = url_for([:console, record, other_params])
        end
      rescue NoMethodError, ActionController::RoutingError
        return nil
      end

      valid_routes_parent = nil

      [ Folio::Engine, main_app ].each do |routes_parent|
        recognized = routes_parent.routes.recognize_path(url, method: :get)

        if recognized && recognized[:controller].include?("/console/")
          valid_routes_parent = routes_parent
          break
        end
      rescue ActionController::RoutingError
      end

      return url if valid_routes_parent

      begin
        if through
          url_for([:edit, :console, through, record])
        else
          url_for([:edit, :console, record])
        end
      rescue NoMethodError, ActionController::RoutingError
        nil
      end
    end

    def folio_console_record_variable_name(plural: false)
      "@#{folio_console_name_base(plural:)}".to_sym
    end

    def folio_console_record
      instance_variable_get(folio_console_record_variable_name)
    end

    def folio_console_records
      instance_variable_get(folio_console_record_variable_name(plural: true))
    end

    def filter_records_by_belongs_to_site
      if records = folio_console_records
        instance_variable_set(folio_console_record_variable_name(plural: true),
                              records.where(site: current_site))
      elsif record = folio_console_record
        if record.persisted? && record.site != current_site
          fail ActiveRecord::RecordNotFound
        end
      end
    end

    def load_belongs_to_site_resource
      # setting i.e. @page makes cancancan skip the load
      if params[:id].present?
        name = folio_console_record_variable_name(plural: false)
        instance_variable_set(name, @klass.where(site: current_site).find(params[:id]))
      end
    end
end
