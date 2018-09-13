# frozen_string_literal: true

module Folio
  class Console::MenusController < Console::BaseController
    before_action :find_menu, except: [:index, :create, :new]
    add_breadcrumb Menu.model_name.human(count: 2), :console_menus_path

    def index
      @menus = Menu.all
    end

    def new
      @menu = Menu.new
    end

    def create
      @menu = Menu.create(menu_params)
      respond_with @menu, location: edit_console_menu_path(@menu)
    end

    def update
      @menu.update(menu_params)
      respond_with @menu, location: edit_console_menu_path(@menu)
    end

    def destroy
      @menu.destroy
      respond_with @menu, location: console_menus_path
    end

    def show
      fail ActionController::MethodNotAllowed unless @menu.supports_nesting?
    end

    def tree_sort
      @menu.transaction do
        params.require(:sortable).each do |index, menu_item|
          next if menu_item[:id].blank?
          @menu.menu_items.find(menu_item[:id])
                          .update!(parent_id: menu_item[:parent_id],
                                   position: index)
        end
      end
    end

    private

      def find_menu
        @menu = Menu.find(params[:id])
      end

      def filter_params
        # params.permit(:by_query, :by_published, :by_type, :by_tag)
      end

      def menu_params
        sti_menu_items params.require(:menu).permit(
          :type,
          :locale,
          menu_items_attributes: [:id,
                                  :title,
                                  :target,
                                  :position,
                                  :type,
                                  :rails_path,
                                  :_destroy]
        )
      end

      def sti_menu_items(params)
        sti_hack(params, :menu_items_attributes, :target)
      end
  end
end
