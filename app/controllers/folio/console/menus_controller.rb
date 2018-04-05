# frozen_string_literal: true

module Folio
  class Console::MenusController < Console::BaseController
    before_action :find_menu, except: [:index, :create, :new]
    add_breadcrumb Menu.model_name.human(count: 2), :console_menus_path

    TYPE_ID_DELIMITER = ' - '

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
          :locale,
          menu_items_attributes: [:id,
                                  :title,
                                  :target,
                                  :position,
                                  :type,
                                  :_destroy]
        ).tap do |obj|
          # STI hack
          if obj[:menu_items_attributes]
            obj[:menu_items_attributes].each do |key, value|
              type, id = value[:target].split(TYPE_ID_DELIMITER)
              obj[:menu_items_attributes][key][:target_type] = type
              obj[:menu_items_attributes][key][:target_id] = id
              obj[:menu_items_attributes][key].delete(:target)
            end
          end

          obj
        end
      end
  end
end
