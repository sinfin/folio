# frozen_string_literal: true

class Folio::Console::MenusController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Menu'

  before_action :serialize_menu_items, except: [:destroy, :index]

  private

    def menu_params
      sti_menu_items(
        params.require(:menu)
              .permit(:type,
                      :locale,
                      menu_items_attributes: menu_items_attributes)
      )
    end

    def menu_items_attributes
      [
        :id,
        :title,
        :target,
        :position,
        :type,
        :rails_path,
        :_destroy,
      ]
    end

    def sti_menu_items(params)
      sti_hack(params, :menu_items_attributes, :target)
    end

    def folio_console_collection_includes
      [ :menu_items ]
    end

    def folio_console_record_includes
      [ :menu_items ]
    end

    def serialize_menu_items
      @serialized_menu_items = @menu.menu_items
                                    .arrange_serializable do |p, ch|
                                      p.to_h.merge(children: ch.map(&:to_h))
                                    end.to_json

      serialized_menu_paths = []
      @menu.class.rails_paths.each do |path, title|
        serialized_menu_paths << {
          title: "#{t('folio.console.menus.link')} - #{title}",
          rails_path: path,
        }
      end

      @menu.available_targets.each do |record|
        record_name = record.try(:to_console_label) ||
                      record.try(:to_label) ||
                      record.try(:title) ||
                      record.model_name.human

        label = [record.model_name.human, record_name].compact.join(' / ')

        serialized_menu_paths << {
          title: ActionController::Base.helpers.truncate(label, length: 50),
          target_type: record.try(:type) || record.class.to_s,
          target_id: record.id,
        }
      end

      @serialized_menu_paths = serialized_menu_paths.to_json
    end
end
