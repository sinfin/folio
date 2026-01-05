# frozen_string_literal: true

class Folio::Console::Files::ShowModalComponent < ApplicationComponent
  CLASS_NAME = "f-c-files-show-modal"

  def initialize(file: nil)
    @file = file
  end

  private
    def data
      stimulus_controller("f-c-files-show-modal",
                          values: {
                            file_data: @file ? { id: @file.id, type: @file.class.to_s } : {},
                            url_mappings: url_mappings.to_json,
                          },
                          action: {
                            "f-c-files-show-modal:openForFileData" => "onOpenForFileData",
                            "f-c-files-show:deleted" => "onFileDeleted",
                            "f-modal:opened" => "onModalOpened",
                            "f-modal:closed" => "onModalClosed",
                          })
    end

    def navigation_buttons_model
      %w[previous next].map do |direction|
        button_data = stimulus_data(action: { click: "onNavigationClick" },
                                    target: "navigationButton#{direction.capitalize}").merge(direction:)

        {
          data: button_data,
          label: t(".navigation_#{direction}"),
          class_name: "f-c-files-show-modal__header-navigation-button",
          icon: direction == "previous" ? :chevron_left : nil,
          right_icon: direction == "next" ? :chevron_right : nil,
          size: :sm,
          variant: :tertiary
        }
      end
    end

    def url_mappings
      h = {}

      Rails.application.config.folio_file_types_for_routes.each do |type|
        h[type] = url_for([:console, type.constantize])
      end

      h
    end
end
