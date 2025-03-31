# frozen_string_literal: true

module Folio::Console::FileControllerBase
  extend ActiveSupport::Concern

  included do
    before_action :set_file_for_show_modal, only: %i[index]
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
      [:file_placements]
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
end
