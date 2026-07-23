# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::CropEditComponent < Folio::Console::ApplicationComponent
  def initialize(file:,
                 ratio:,
                 ratio_label:,
                 thumbnail_size_keys:,
                 updated_thumbnails_crop: false,
                 variant: :tile,
                 group_type: "crop")
    @file = file
    @ratio = ratio
    @ratio_label = ratio_label
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
    @variant = variant
    @group_type = group_type
  end

  attr_reader :ratio_label

  private
    def before_render
      @can_update = can_now?(:update, @file) && @file.file_width.present? && @file.file_height.present?
    end

    # Representative preview URL for the tile thumbnail. Picks the largest
    # already-generated size of this ratio and resolves it through the same
    # CDN / temporary-url rewriting the detail thumbnails use, so the preview
    # is not a raw (and on review unreachable) Dragonfly/doader URL.
    def image_url
      return @image_url if defined?(@image_url)

      @image_url = Folio::Console::Files::Show::Thumbnails::RepresentativeImage
                     .representative_url(file: @file,
                                         keys: @thumbnail_size_keys,
                                         include_doader: @updated_thumbnails_crop)
    end

    def image_data
      stimulus_thumbnail(src: image_url)
    end

    # Inline aspect-ratio for the tile box so a 16:9 crop renders wide and a
    # 3:4 crop tall, at a fixed height (set in CSS).
    def thumb_style
      width, height = @ratio.split(":", 2).map(&:to_i)
      return "" if width.zero? || height.zero?

      "aspect-ratio: #{width} / #{height};"
    end

    def modal_buttons
      render(Folio::Console::Ui::ButtonsComponent.new(
        class_name: "f-c-files-show-thumbnails-crop-edit__buttons",
        buttons: [{
          variant: :light,
          data: stimulus_action(click: "saveEditing"),
          label: t("folio.console.actions.save"),
        }, {
          variant: :medium_dark,
          data: stimulus_action(click: "cancelEditing"),
          label: t("folio.console.actions.cancel")
        }]
      ))
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
                            "f-thumbnail:newData" => "thumbnailUpdated"
                          })
    end

    def cropper_data
      crop = @file.thumbnail_configuration&.dig("ratios", @ratio, "crop") || {}

      {
        aspect_ratio: cropper_aspect_ratio,
        **(stored_crop_position(crop) || gravity_crop_position),
      }
    end

    def cropper_aspect_ratio
      width, height = @ratio.split(":", 2).map(&:to_f)
      width / height
    end

    def stored_crop_position(crop)
      x, y = crop.values_at("x", "y")
      return unless x.is_a?(Numeric) || y.is_a?(Numeric)

      {
        x: x.is_a?(Numeric) ? x.to_f : 0,
        y: y.is_a?(Numeric) ? y.to_f : 0,
      }
    end

    def gravity_crop_position
      horizontal_range, vertical_range = crop_position_ranges
      horizontal_factor, vertical_factor = gravity_factors

      {
        x: horizontal_range * horizontal_factor,
        y: vertical_range * vertical_factor,
      }
    end

    def crop_position_ranges
      width = @file.file_width.to_f
      height = @file.file_height.to_f
      return [0, 0] unless width.positive? && height.positive?

      image_ratio = width / height

      if image_ratio > cropper_aspect_ratio
        [1 - cropper_aspect_ratio / image_ratio, 0]
      else
        [0, 1 - image_ratio / cropper_aspect_ratio]
      end
    end

    def gravity_factors
      case @file.default_gravity
      when "east" then [1, 0.5]
      when "west" then [0, 0.5]
      when "north" then [0.5, 0]
      when "south" then [0.5, 1]
      else [0.5, 0.5]
      end
    end

    def api_data
      {
        group_type: @group_type,
        ratio: @ratio,
      }
    end
end
