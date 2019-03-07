# frozen_string_literal: true

class Folio::Console::PagesController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Page'

  def index
    @pages = @pages.ordered
  end

  def create
    @page = Folio::Page.create(page_params)
    respond_with @page
  end

  def update
    @page.update(page_params)
    respond_with @page
  end

  def destroy
    @page.destroy
    respond_with @page
  end

  def index_filters
    {
      by_type: Folio::Page.recursive_subclasses.map do |klass|
                 [klass.model_name.human, klass]
               end,
      by_published: [true, false],
    }
  end

  private

    def page_params
      sti_atoms(
        params.require(:page)
              .permit(*(Folio::Page.column_names - ['id']),
                      *atoms_strong_params,
                      *file_placements_strong_params)
      )
    end
end
