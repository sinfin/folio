# frozen_string_literal: true

require "csv"

class Folio::Console::BaseController < Folio::ApplicationController
  include Folio::Console::DefaultActions
  include Folio::Console::Includes
  include Folio::ErrorsControllerBase
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :custom_authorize_user!

  before_action :add_root_breadcrumb

  before_action :update_current_user_console_url
  before_action :set_show_current_user_console_url_bar

  before_action do
    if (params[:rmp] && can_now?(:display_miniprofiler)) || ENV["FORCE_MINI_PROFILER"]
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

    respond_to :json, only: %i[update]

    if through
      through_as = through.demodulize.underscore
      through_klass = through.constantize

      if through_klass.try(:has_belongs_to_site?)
        before_action :load_belongs_to_site_through_resource
        load_and_authorize_resource(through_as, class: through)
      else
        load_and_authorize_resource(through_as, class: through)
      end

      # keep this above load_and_authorize_resource
      if klass.try(:has_belongs_to_site?)
        before_action :load_belongs_to_site_resource
      end

      load_and_authorize_resource(as, class: class_name,
                                      except:,
                                      parent: (false if as.present?),
                                      through: through_as)
    else
      # keep this above load_and_authorize_resource
      if klass.try(:has_belongs_to_site?)
        before_action :load_belongs_to_site_resource
      end

      load_and_authorize_resource(as, class: class_name,
                                      except:,
                                      parent: (false if as.present?))
    end

    if klass.try(:audited_console_enabled?)
      before_action :load_revisions, only: [:edit, :revision]
      before_action :find_revision, only: %i[revision restore]
    end

    # keep this under load_and_authorize_resource
    if klass.try(:has_belongs_to_site?)
      before_action :filter_records_by_belongs_to_site
    end

    before_action :add_through_breadcrumbs
    before_action :add_collection_breadcrumbs
    before_action :add_record_breadcrumbs

    before_action(:filter_folio_console_collection)

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
    params.permit(:by_label_query, *index_filters_keys)
  end

  def safe_url_for(opts)
    url_for(opts)
  rescue StandardError
    begin
      main_app.url_for(opts)
    rescue StandardError
    end
  end

  helper_method :through_aware_console_url_for

  def through_aware_console_url_for(record, action: nil, hash: {}, safe: false)
    through_record = if try(:folio_console_controller_for_through)
      through_record_name = folio_console_controller_for_through.constantize.model_name.element
      instance_variable_get(:"@#{through_record_name}")
    end

    hash ||= {}
    hash[:action] = action

    opts = [:console]
    opts << through_record if through_record
    opts << record
    opts << hash

    if safe
      safe_url_for(opts)
    else
      url_for(opts)
    end
  end

  helper_method :through_aware_console_url_for

  def set_i18n_locale
    I18n.locale = if params[:locale] && Folio::Current.site.locales.include?(params[:locale])
      params[:locale]
    else
      Folio::Current.site.console_locale
    end
  end

  private
    def index_filters
      {}
    end

    def index_filters_keys
      @index_filters_keys ||= begin
        ary = []

        index_filters.each do |key, config|
          if config.is_a?(Hash) && config[:as] == :numeric_range
            ary << :"#{key}_from"
            ary << :"#{key}_to"
          else
            ary << key
          end
        end

        ary
      end
    end

    def add_root_breadcrumb
      add_breadcrumb cell("folio/ui/icon", :home, height: 16).show.html_safe, console_root_path
    end

    def additional_file_placements_strong_params_keys
      []
    end

    def additional_private_attachments_strong_params_keys
      []
    end

    def file_placements_strong_params
      commons = %i[id
                   title
                   alt
                   tag_list
                   file_id
                   position
                   type
                   _destroy]

      hash = {}

      (additional_file_placements_strong_params_keys + %i[
        og_image_placement_attributes
        cover_placement_attributes
        audio_cover_placement_attributes
        video_cover_placement_attributes
        background_cover_placement_attributes
        document_placement_attributes
        document_placements_attributes
        image_placements_attributes
      ]).each do |key|
        hash[key] = commons
      end

      [hash]
    end

    def private_attachments_strong_params
      commons = %i[id title alt file type position _destroy]
      hash = { private_attachments_attributes: commons }

      additional_private_attachments_strong_params_keys.each do |key|
        hash[key] = commons
      end

      [hash]
    end

    def atoms_strong_params
      base = [:id,
              :type,
              :position,
              :placement_type,
              :_destroy,
              *file_placements_strong_params] + Folio::Atom.strong_params

      [{ atoms_attributes: base }] + Folio::Current.site.locales.map do |locale|
        {
          "#{locale}_atoms_attributes": base,
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
                                       _destroy],
        },
      ]
    end

    def folio_attributes_strong_params
      [
        {
          folio_attributes_attributes: %i[id
                                          value
                                          folio_attribute_type_id
                                          _destroy] + I18n.available_locales.map do |locale|
                                            "value_#{locale}".to_sym
                                          end
        },
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
      [
        :use_secondary_address,
        primary_address_attributes: base_address_attributes,
        secondary_address_attributes: base_address_attributes
      ]
    end

    def sti_hack(params, nested_name, relation_name)
      params.tap do |obj|
        # STI hack
        if obj[nested_name]
          relation_type = :"#{relation_name}_type"
          relation_id = :"#{relation_name}_id"

          obj[nested_name].each do |key, value|
            next if value[relation_name].nil?

            type, id = value[relation_name].split(TYPE_ID_DELIMITER)
            obj[nested_name][key][relation_type] = type
            obj[nested_name][key][relation_id] = id
            obj[nested_name][key].delete(relation_name)
          end
        end
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

      name ||= klass.model_name.human(count: 2)

      filename = "#{name}-#{Date.today}.csv".split(".")
                                            .map(&:parameterize)
                                            .join(".")
      send_data data, filename:
    end

    def index_tabs; end

    helper_method :index_tabs

    def load_revisions
      return unless folio_console_record && folio_console_record.respond_to?(:revisions)

      scope = folio_console_record.audits
                                  .includes(:user)
                                  .unscope(:order)
                                  .order(version: :desc)

      if Rails.application.config.folio_console_audited_revisions_limit
        scope = scope.limit(Rails.application.config.folio_console_audited_revisions_limit + 1)
      end

      @audited_audits = scope
    end

    def find_revision
      scope = if Rails.application.config.folio_console_audited_revisions_limit
        max_version = folio_console_record.audits.maximum(:version)

        if max_version
          min_version = max_version - Rails.application.config.folio_console_audited_revisions_limit
          folio_console_record.audits.where(version: min_version..)
        else
          folio_console_record.audits
        end
      else
        folio_console_record.audits
      end

      @audited_audit = scope.find_by_version!(params[:version])

      @audited_revision = @audited_audit.revision

      if @audited_revision.try(:type)
        @audited_revision = @audited_revision.becomes(@audited_revision.type.constantize)
      end

      @audited_revision.reconstruct_folio_audited_data(audit: @audited_audit)
    end

    def add_through_breadcrumbs
      return unless folio_console_controller_for_through

      through_klass = folio_console_controller_for_through.constantize

      add_breadcrumb(through_klass.model_name.human(count: 2),
                     url_for([:console, through_klass]))

      through_record = instance_variable_get(:"@#{through_klass.model_name.element}")

      return unless through_record

      add_breadcrumb(through_record.to_label,
                     console_show_or_edit_path(through_record, include_through_record: false))
    end

    def add_collection_breadcrumbs
      add_breadcrumb(@klass.model_name.human(count: 2),
                     through_aware_console_url_for(@klass, safe: true))
    end

    def add_record_breadcrumbs
      if folio_console_record
        if folio_console_record.new_record?
          add_breadcrumb I18n.t("folio.console.breadcrumbs.actions.new")
        else
          record_url = console_show_or_edit_path(folio_console_record)
          add_breadcrumb(folio_console_record.to_label, record_url)
        end
      end
    rescue StandardError
      add_breadcrumb(folio_console_record.to_label)
    end

    def custom_authorize_user!
      if respond_to?(:custom_authenticate_account!)
        custom_authenticate_account! # includes authorization
      elsif respond_to?(:custom_authenticate_user!)
        custom_authenticate_user!
      else
        authenticate_user!
      end

      if params[:action].to_sym == :stop_impersonating
        authorize!(:stop_impersonating, Folio::User)
      else
        authorize!(:access_console, Folio::Current.site)
      end
    end

    def console_show_or_edit_path(record, other_params: {}, include_through_record: true)
      return nil if record.nil?

      begin
        url = if include_through_record
          through_aware_console_url_for(record, hash: other_params)
        else
          url_for([:console, record, other_params])
        end
      rescue NoMethodError, ActionController::RoutingError
        return nil
      end

      valid_routes_parent = nil

      [Folio::Engine, main_app].each do |routes_parent|
        recognized = routes_parent.routes.recognize_path(url, method: :get)

        if recognized && recognized[:controller].include?("/console/")
          valid_routes_parent = routes_parent
          break
        end
      rescue ActionController::RoutingError
      end

      return url if valid_routes_parent

      begin
        if include_through_record
          through_aware_console_url_for(record, action: :edit)
        else
          url_for([:console, record, action: :edit])
        end
      rescue NoMethodError, ActionController::RoutingError
        nil
      end
    end

    def folio_console_record_variable_name(plural: false)
      :"@#{folio_console_name_base(plural:)}"
    end

    def folio_console_record
      instance_variable_get(folio_console_record_variable_name)
    end

    def folio_console_records
      instance_variable_get(folio_console_record_variable_name(plural: true))
    end

    def filter_records_by_belongs_to_site
      if folio_console_records
        instance_variable_set(folio_console_record_variable_name(plural: true),
                              folio_console_records.by_site(allowed_record_sites))
      elsif record = folio_console_record
        if record.persisted? && !allowed_record_sites.map(&:id).include?(record.site.id)
          raise ActiveRecord::RecordNotFound
        end
      end
    end

    def allowed_record_sites
      [Folio::Current.site]
    end

    def load_belongs_to_site_resource
      # setting i.e. @page makes cancancan skip the load
      return unless params[:id].present?

      name = folio_console_record_variable_name(plural: false)
      if @klass.respond_to?(:friendly)
        instance_variable_set(name, @klass.by_site(allowed_record_sites).friendly.find(params[:id]))
      else
        instance_variable_set(name, @klass.by_site(allowed_record_sites).find(params[:id]))
      end
    end

    def load_belongs_to_site_through_resource
      through_record_name = folio_console_controller_for_through.constantize.model_name.element
      param = params["#{through_record_name}_id".to_sym]

      return unless param.present?

      name = "@#{through_record_name}"

      through_klass = folio_console_controller_for_through.constantize

      if through_klass.respond_to?(:friendly)
        instance_variable_set(name, through_klass.by_site(allowed_record_sites).friendly.find(param))
      else
        instance_variable_set(name, through_klass.by_site(allowed_record_sites).find(param))
      end
    end

    def filter_folio_console_collection
      return unless collection_action?

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

      return unless params[:sort].instance_variable_get(name).respond_to?(:sort_by_params)

      filtered = instance_variable_get(name).filter_by_params(filter_params)
      instance_variable_set(name, filtered)
    end

    def update_current_user_console_url
      return unless can_now?(:access_console)
      return if request.path.start_with?("/console/api")
      return if request.path.start_with?("/console/atoms")

      Folio::Current.user.update_console_url!(request.url)
    end

    def set_show_current_user_console_url_bar
      @show_current_user_console_url_bar = %w[edit update].include?(action_name)
    end

    def member_action?
      return @member_action unless @member_action.nil?

      @member_action = %w[new create].include?(action_name) || params[:id].present?
    end

    def collection_action?
      return @collection_action unless @collection_action.nil?

      @collection_action = !member_action?
    end

    def traco_aware_param_names(*param_names_to_localize)
      localized_params = []
      locales_matcher = "(#{I18n.available_locales.join("|")})"

      param_names_to_localize.each do |param_name|
        found_localized_param = false

        @klass.column_names.each do |column_name|
          if column_name.match?(/\A#{param_name}_#{locales_matcher}\z/)
            localized_params << column_name.to_sym
            found_localized_param = true
          end
        end

        unless found_localized_param
          localized_params << param_name
        end
      end

      localized_params
    end

    def folio_using_traco_aware_param_names(*param_names_to_localize)
      if Rails.application.config.folio_using_traco
        traco_aware_param_names(*param_names_to_localize)
      else
        param_names_to_localize
      end
    end
end
