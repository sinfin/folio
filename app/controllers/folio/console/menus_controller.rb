# frozen_string_literal: true

module Folio
  class Console::MenusController < Console::BaseController
    before_action :find_menu, except: [:index, :create, :new]

    add_breadcrumb(I18n.t('folio.console.menus.index.title'),
                   :console_menus_path)

    def index
      @menus = Menu.all
    end

    def new
      @menu = Menu.new()
    end

    def create
      @menu = Menu.create(menu_params)
      respond_with @menu, location: console_menus_path
    end

    def update
      @menu.update(menu_params)
      respond_with @menu, location: console_menus_path
    end

    def destroy
      @menu.destroy
      respond_with @menu, location: console_menus_path
    end

  private
    def find_menu
      @menu = Menu.find(params[:id])
    end

    def filter_params
      # params.permit(:by_query, :by_published, :by_type, :by_tag)
    end

    def menu_params
      params.require(:menu).permit(
        :type,
        menu_items_attributes: [:id, :type, :title, :rails_path, :node_id,
                                :position, :_destroy]
      )
    end
  end
end
