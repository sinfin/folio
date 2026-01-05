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
      return @image_url if @image_url
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

      @image_url = @file.thumb(highest_area_key).url
    end

    def image_data
      stimulus_thumbnail(src: image_url)
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
                            mode:,
                          },
                          action: {
                            "f-thumbnail:newData" => "thumbnailUpdated"
                          })
    end

    def editor_inner_style
      "width: #{image_width}px; height: #{image_height}px;"
    end

    def cropper_aspect_ratio
      @cropper_aspect_ratio ||= begin
        width, height = @ratio.split(":", 2).map(&:to_i)
        width.to_f / height.to_f
      end
    end

    def cropper_data
      data = {
        aspect_ratio: cropper_aspect_ratio,
        relative_x: 0,
        relative_y: 0,
      }

      if @file.thumbnail_configuration.present? &&
         @file.thumbnail_configuration["ratios"].present? &&
         @file.thumbnail_configuration["ratios"][@ratio].present? &&
         @file.thumbnail_configuration["ratios"][@ratio]["crop"].present?
        crop = @file.thumbnail_configuration["ratios"][@ratio]["crop"]
        data[:relative_x] = crop["x"].to_f if crop["x"].is_a?(Numeric)
        data[:relative_y] = crop["y"].to_f if crop["y"].is_a?(Numeric)
      end

      data[:x] = image_width * data[:relative_x]
      data[:y] = image_height * data[:relative_y]

      if mode == "fixed-width"
        data[:selection_width] = image_width
        data[:selection_height] = data[:selection_width] / cropper_aspect_ratio
      else
        data[:selection_height] = image_height
        data[:selection_width] = data[:selection_height] * cropper_aspect_ratio
      end

      data
    end

    def image_width
      @image_width ||= if file_aspect_ratio >= 1
        290
      else
        (290 * @file.file_width.to_f / @file.file_height.to_f).round(4)
      end
    end

    def image_height
      @image_height ||= if file_aspect_ratio >= 1
        (290 * @file.file_height.to_f / @file.file_width.to_f).round(4)
      else
        290
      end
    end

    def api_data
      {
        thumbnail_size_keys: @thumbnail_size_keys,
        ratio: @ratio,
      }
    end

    def file_aspect_ratio
      @file_aspect_ratio ||= @file.file_width.to_f / @file.file_height.to_f
    end

    def mode
      @mode ||= if file_aspect_ratio > cropper_aspect_ratio
        "fixed-height"
      else
        "fixed-width"
      end
    end
end
