# frozen_string_literal: true

module Folio::Console::FileControllerIndexFilters
  extend ActiveSupport::Concern

  included do
    helper_method :file_usage_record
  end

  private
    def index_filters
      filters = {
        by_query: { as: :text, icon: :magnify },
        created_by_current_user: { as: :boolean },
        by_used: [true, false],
        by_tag_id: {
          klass: "ActsAsTaggableOn::Tag",
        },
      }

      if @klass.included_modules.include?(Folio::File::HasUsageConstraints)
        filters[:by_usage_constraints] = @klass.usage_constraints_for_select
        filters[:by_media_source] = { klass: "Folio::MediaSource", order_scope: :ordered }

        if Rails.application.config.folio_shared_files_between_sites
          filters[:by_allowed_site_slug] = Folio::Site.ordered.map { |site| [site.to_label, site.slug] }
        end

        if file_usage_record
          filters[Folio::File::UsageRecord::PARAM] = { as: :hidden, persistent: true }
        end
      end

      filters
    end

    def file_usage_record
      return @file_usage_record if defined?(@file_usage_record)

      @file_usage_record = nil
      return unless file_picker_request?

      @file_usage_record = Folio::File::UsageRecord.from_param(params[Folio::File::UsageRecord::PARAM])
    end

    def file_picker_request?
      return true if action_name.in?(%w[index_for_picker index_for_modal])

      action_name == "pagination" && pagination_request_path.end_with?("/index_for_picker", "/index_for_modal")
    end

    def folio_console_collection_filter_params
      return super unless filter_by_usage_constraints_for_usage_record?

      super.except(:by_usage_constraints)
    end

    def filter_folio_console_collection
      super
      return unless filter_by_usage_constraints_for_usage_record?

      name = folio_console_record_variable_name(plural: true)
      records = instance_variable_get(name).by_usage_constraints_for_usage_record(params[:by_usage_constraints],
                                                                                  file_usage_record)
      instance_variable_set(name, records)
    end

    def filter_by_usage_constraints_for_usage_record?
      collection_action? &&
        file_usage_record.present? &&
        params[:by_usage_constraints].present? &&
        @klass.included_modules.include?(Folio::File::HasUsageConstraints)
    end
end
