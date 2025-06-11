# frozen_string_literal: true

class Folio::Console::PagesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Page"

  def index
    @catalogue_options = {}

    if Rails.application.config.folio_pages_ancestry
      @catalogue_model = @pages.arrange(order: :position)
      @catalogue_options = { ancestry: true }
    else
      super
      @catalogue_model = @pages
    end
  end

  private
    def index_filters
      {
        by_locale: Rails.application.config.folio_pages_locales ? Folio::Current.site.locales : nil,
        by_type: Folio::Page.recursive_subclasses.map do |klass|
                   [klass.model_name.human, klass]
                 end,
        by_published: [true, false],
      }.compact
    end

    def additional_page_params
      # to be overriden in main_app should it be needed
      []
    end

    def page_params
      params.require(:page)
            .permit(*folio_using_traco_aware_param_names(:title, :perex, :slug, :meta_title, :meta_description),
                    :type,
                    :position,
                    :published,
                    :published_at,
                    :locale,
                    :tag_list,
                    :parent_id,
                    *atoms_strong_params,
                    *file_placements_strong_params,
                    *console_notes_strong_params,
                    *additional_page_params)
    end

    def folio_console_record_includes
      [cover_placement: :file]
    end
end
