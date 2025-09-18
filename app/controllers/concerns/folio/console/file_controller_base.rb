# frozen_string_literal: true

module Folio::Console::FileControllerBase
  extend ActiveSupport::Concern

  PAGY_ITEMS = 64

  included do
    before_action :set_file_for_show_modal, only: %i[index]
    after_action :message_bus_broadcast_update, only: %i[update]
  end

  def index
    set_pagy_options

    @turbo_frame_id = @klass.console_turbo_frame_id(modal: action_name == "index_for_modal",
                                                    picker: action_name == "index_for_picker")

    apply_site_filtering_for_non_index_context

    super
  end

  def index_for_modal
    index
  end

  def index_for_picker
    @barebone_layout_for_turbo_frame = true

    index
  end

  def show
    super
    @skip_folio_files_show_modal = true
    @file = folio_console_record
    # need specific content_type to avoid double rendering error via turbo
    render "folio/console/file/show", content_type: "text/html"
  end

  def file_placements
    show
  end

  def extract_metadata
    if folio_console_record.respond_to?(:extract_metadata!)
      folio_console_record.extract_metadata!(force: true,
                                             user_id: Folio::Current.user&.id)
    end

    redirect_to url_for([:console, folio_console_record, uncollapse: "metadata"])
  end

  private
    def file_params
      ary = [
        :headline,
        :description,
        :tag_list,
        :author,
        :attribution_source,
        :attribution_source_url,
        :attribution_copyright,
        :attribution_licence,
        :attribution_max_usage_count,
        :sensitive_content,
        :default_gravity,
        :alt,
        tags: []
      ]

      test_instance = @klass.new

      if test_instance.try(:console_show_additional_fields).present?
        ary += test_instance.console_show_additional_fields.keys
      end

      p = params.require(:file)
                .permit(*ary)

      if p[:tags].present? && p[:tag_list].blank?
        p[:tag_list] = p.delete(:tags).join(",")
      end

      p
    end

    # manually set method overriding default_actions
    def folio_console_params
      file_params
    end

    def folio_console_record_includes
      [:tags]
    end

    def folio_console_collection_includes
      includes = [:tags]

      if @klass.included_modules.include?(Folio::File::HasUsageConstraints)
        includes << :allowed_sites
      end

      includes
    end

    def index_view_name
      "folio/console/file/index"
    end

    def set_file_for_show_modal
      file_id = params[:file_id]
      return if file_id.blank?

      @folio_file_for_show_modal = @klass.by_site(Folio::Current.site)
                                         .accessible_by(Folio::Current.ability)
                                         .find(file_id)
    end

    def set_pagy_options
      @pagy_options = {
        reload_url: url_for([:pagination, :console, :api, @klass, page: params[:page]]),
        skip_default_layout_pagination: true,
      }

      if @klass.human_type == "image"
        @pagy_options[:middle_component] = Folio::Console::Files::DisplayToggleComponent.new
      end

      @pagy_options
    end

    def index_pagy_items_per_page
      PAGY_ITEMS
    end

    def message_bus_broadcast_update
      return if folio_console_record.saved_changes.blank?

      user_ids = Folio::User.where.not(console_url: nil)
                            .where(console_url_updated_at: 1.hour.ago..)
                            .pluck(:id)

      return if user_ids.blank?

      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::Console::FileControllerBase/file_updated",
                           data: { id: folio_console_record.id },
                         }.to_json,
                         user_ids:
    end

    def index_filters
      filters = {
        by_used: [true, false]
      }

      if @klass.included_modules.include?(Folio::File::HasUsageConstraints)
        filters[:by_usage_constraints] = @klass.usage_constraints_for_select
        filters[:by_media_source] = { klass: "Folio::MediaSource", order_scope: :ordered }

        if Rails.application.config.folio_shared_files_between_sites
          filters[:by_allowed_site_slug] = Folio::Site.ordered.map { |site| [site.to_label, site.slug] }
        end
      end

      filters
    end

    def allowed_record_sites
      if Rails.application.config.folio_shared_files_between_sites
        [Folio::Current.main_site, Folio::Current.site]
      else
        [Folio::Current.site]
      end
    end

    def response_with_json_for_valid_update
      data = {}
      meta = {}

      folio_console_params.keys.each do |key|
        change = folio_console_record.saved_changes[key]

        if change && change[1]
          if key.to_s.ends_with?("_id")
            if label = folio_console_record.try(key.to_s.chomp("_id")).try(:to_label)
              meta[:labels] ||= {}
              meta[:labels][key] = label
            end
          end

          data[key] = change[1]
        elsif key == "preview_duration"
          data[key] = folio_console_record.preview_duration
        end
      end

      render json: { data:, meta: }, status: 200
    end

    def apply_site_filtering_for_non_index_context
      return if action_name == "index"
      return unless @klass.included_modules.include?(Folio::File::HasUsageConstraints)

      collection_name = folio_console_record_variable_name(plural: true)
      collection = instance_variable_get(collection_name)

      # Filter for usable files (includes both usage limits and site restrictions)
      collection = collection.by_usage_constraints("usable")

      instance_variable_set(collection_name, collection)
    end
end
