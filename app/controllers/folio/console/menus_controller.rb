# frozen_string_literal: true

class Folio::Console::MenusController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Menu"

  def new
    @menu = @klass.new(type: params[:type])
  end

  def edit
    serialize_menu_items
  end

  def update
    @klass.transaction do
      dict = {}

      if menu_params[:title]
        @menu.update!(title: menu_params[:title])
      end

      if menu_params[:menu_items_attributes]
        menu_params[:menu_items_attributes].each do |_i, mia|
          if mia[:id].blank?
            menu_item = @menu.menu_items.create(mia)
          else
            menu_item = @menu.menu_items.find(mia[:id])
            if mia[:_destroy]
              menu_item.destroy
              next
            else
              menu_item.update(mia)
            end
          end
          dict[mia[:unique_id]] = menu_item
        end

        menu_params[:menu_items_attributes].each do |_i, mia|
          next if mia[:_destroy]
          dict[mia[:unique_id]].update(parent: dict[mia[:parent_unique_id]])
        end
      end
    end

    serialize_menu_items
    respond_with @menu, location: url_for([:edit, :console, @menu])
  end

  private
    def index_filters
      {
        by_type: Folio::Menu.recursive_subclasses(include_self: false).map do |klass|
                   [klass.model_name.human, klass]
                 end,
      }
    end

    def menu_params
      p = %i[title]
      p += %i[type locale] if action_name == "create"

      params.require(:menu)
            .permit(*p, menu_items_attributes: menu_items_attributes)
    end

    def menu_items_attributes
      Folio::MenuItem.column_names + %w[unique_id parent_unique_id _destroy]
    end

    def folio_console_collection_includes
      []
    end

    def folio_console_record_includes
      []
    end

    def serialize_menu_items
      @serialized_menu_items = @menu.menu_items
                                    .arrange_serializable do |p, ch|
                                      p.to_h.merge(children: ch.map(&:to_h))
                                    end.to_json

      serialized_menu_paths = []
      @menu.class.rails_paths.each do |path, title|
        serialized_menu_paths << {
          title: title,
          label: "#{t('folio.console.menus.link')} - #{title}",
          rails_path: path,
        }
      end

      @menu.available_targets.each do |record|
        record_name = record.try(:to_console_label) ||
                      record.try(:to_label) ||
                      record.try(:title) ||
                      record.model_name.human

        label = [record.model_name.human, record_name].compact.join(" / ")

        serialized_menu_paths << {
          title: record_name,
          label: ActionController::Base.helpers.truncate(label, length: 50),
          target_type: record.class.base_class.to_s,
          target_id: record.id,
        }
      end

      @serialized_menu_paths = serialized_menu_paths.to_json
    end
end
