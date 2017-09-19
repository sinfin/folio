# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Console::MenusController < Console::BaseController
    before_action :find_menu, except: [:index, :create, :new]

    def index
      @menus = Folio::Menu.all
    end

    def new
      @menu = Folio::Menu.new()
    end

    def create
      @menu = Folio::Menu.create(menu_params)
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
      @menu = Folio::Menu.find(params[:id])
    end

    def filter_params
      # params.permit(:by_query, :by_published, :by_type, :by_tag)
    end

    def menu_params
      p = params.require(:menu).permit(:type, menu_items_attributes: [:id, :type, :title, :rails_path, :node_id, :position, :_destroy])
    end
  end
end
