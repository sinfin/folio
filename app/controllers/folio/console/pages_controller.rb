# frozen_string_literal: true

class Folio::Console::PagesController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Page'

  def index
    @pages = @pages.ordered
  end

  private
    def index_filters
      {
        by_type: Folio::Page.recursive_subclasses.map do |klass|
                   [klass.model_name.human, klass]
                 end,
        by_published: [true, false],
      }
    end

    def page_params
      params.require(:page)
            .permit(*(Folio::Page.column_names - ['id'] + ['tag_list']),
                    *atoms_strong_params,
                    *file_placements_strong_params)
    end

    def folio_console_record_includes
      [cover_placement: :file]
    end
end
