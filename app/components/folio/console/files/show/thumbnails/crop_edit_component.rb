# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::CropEditComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, thumbnail_size_keys:, updated_thumbnails_crop: false)
    @file = file
    @ratio = ratio
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
  end

  private
    def before_render
      @can_update = can_now?(:update, @file) && @file.file_width.present? && @file.file_height.present?
    end

    def image_url
      return nil if @thumbnail_size_keys.empty?

      valid_keys = if @updated_thumbnails_crop
        @thumbnail_size_keys
      else
        @thumbnail_size_keys.reject do |key|
          url = @file.thumb(key).url
          url&.start_with?("https://doader")
        end
      end

      return nil if valid_keys.empty?

      highest_area_key = valid_keys.max_by do |key|
        dimensions = key.gsub(/[#>^]$/, "")
        width_str, height_str = dimensions.split("x", 2)

        if width_str.nil? || width_str.empty?
          height_str.to_i
        elsif height_str.nil? || height_str.empty?
          width_str.to_i
        else
          width_str.to_i * height_str.to_i
        end
      end

      @file.thumb(highest_area_key).url
    end

    def buttons_while_editing
      render(Folio::Console::Ui::ButtonsComponent.new(class_name: "f-c-files-show-thumbnails-crop-edit__buttons-while-editing",
                                                      buttons: [{
                                                        variant: :success,
                                                        size: :sm,
                                                        icon: :check,
                                                        data: stimulus_action(click: "saveEditing"),
                                                        label: t("folio.console.actions.save"),
                                                      }, {
                                                        variant: :danger,
                                                        size: :sm,
                                                        icon: :close,
                                                        data: stimulus_action(click: "cancelEditing"),
                                                        label: t("folio.console.actions.cancel")
                                                      }]))
    end

    def buttons
      render(Folio::Console::Ui::ButtonsComponent.new(class_name: "f-c-files-show-thumbnails-crop-edit__buttons",
                                                      buttons: [{
                                                        variant: :warning,
                                                        size: :sm,
                                                        icon: :crop,
                                                        data: stimulus_action(click: "startEditing"),
                                                        label: t(".edit")
                                                      }]))
    end

    def data
      stimulus_controller("f-c-files-show-thumbnails-crop-edit",
                          values: {
                            state: @updated_thumbnails_crop ? "waiting-for-thumbnail" : "viewing",
                            cropper_data: cropper_data.to_json,
                            api_url: url_for([:console, :api, @file, action: :update_thumbnails_crop]),
                            api_data: api_data.to_json,
                          },
                          action: {
                            "Folio::GenerateThumbnailJob/updated" => "thumbnailUpdated"
                          })
    end

    def editor_inner_style
      if @file.file_width > @file.file_height
        "width: 100%; aspect-ratio: #{@file.file_width} / #{@file.file_height};"
      else
        "height: 100%; aspect-ratio: #{@file.file_width} / #{@file.file_height};"
      end
    end

    def cropper_data
      width, height = @ratio.split(":", 2).map(&:to_i)

      {
        aspect_ratio: width.to_f / height.to_f,
      }
    end

    def api_data
      {
        thumbnail_size_keys: @thumbnail_size_keys,
        ratio: @ratio,
      }
    end
end
