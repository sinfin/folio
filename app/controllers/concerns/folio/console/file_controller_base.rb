# frozen_string_literal: true

module Folio::Console::FileControllerBase
  extend ActiveSupport::Concern

  PAGY_ITEMS = 64

  included do
    before_action :set_file_for_show_modal, only: %i[index]
    before_action :set_pagy_options, only: %i[index]
    after_action :message_bus_broadcast_update, only: %i[update]
  end

  def index
    @turbo_frame_id = @klass.console_turbo_frame_id(modal: action_name == "index_for_modal",
                                                    picker: action_name == "index_for_picker")

    super
  end

  def index_for_modal
    index
  end

  def index_for_picker
    index
  end

  private
    def file_params
      p = params.require(:file)
                .permit(:tag_list,
                        :author,
                        :attribution_source,
                        :attribution_source_url,
                        :attribution_copyright,
                        :attribution_licence,
                        :description,
                        :sensitive_content,
                        :default_gravity,
                        :alt,
                        tags: [])

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
      {
        by_used: [true, false],
      }
    end

    def allowed_record_sites
      if Rails.application.config.folio_shared_files_between_sites
        [Folio::Current.main_site, Folio::Current.site]
      else
        [Folio::Current.site]
      end
    end
end
