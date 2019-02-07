# frozen_string_literal: true

class Folio::Console::PagesController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Page'

  def index
    @pages = @pages.ordered
    # if misc_filtering?
    #   if params[:by_parent].present?
    #     parent = Folio::Page.find(params[:by_parent])
    #     @pages = parent.subtree
    #                    .filter_by_params(filter_params)
    #                    .arrange(order: 'position asc, created_at asc')
    #   else
    #     pages = Folio::Page.filter_by_params(filter_params)
    #     @pagy, @pages = pagy(pages)
    #   end
    # else
    #   @limit = self.class.index_children_limit
    #   @pages = Folio::Page.arrange(order: 'position asc, created_at asc')
    # end
  end

  def create
    @page = Folio::Page.create(page_params)
    respond_with @page, location: { action: :index }
  end

  def update
    @page.update(page_params)
    respond_with @page, location: { action: :index }
  end

  def destroy
    @page.destroy
    respond_with @page, location: { action: :index }
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
