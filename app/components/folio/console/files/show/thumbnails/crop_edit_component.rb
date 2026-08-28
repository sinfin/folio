# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::CropEditComponent < Folio::Console::ApplicationComponent
  MAIN_PREVIEW_HEIGHT = 120

  def initialize(file:,
                 ratio:,
                 ratio_label:,
                 thumbnail_size_keys:,
                 updated_thumbnails_crop: false,
                 variant: :tile,
                 group_label: nil,
                 group_type: "crop")
    @file = file
    @ratio = ratio
    @ratio_label = ratio_label
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
    @variant = variant
    @group_label = group_label
    @group_type = group_type
  end

  attr_reader :ratio_label

  private
    def before_render
      @can_update = can_now?(:update, @file) && @file.file_width.present? && @file.file_height.present?
    end

    def image_url
      return @image_url if defined?(@image_url)

      @image_url = if main_preview?
        resolved_main_preview_url
      else
        representative_image.representative_url(file: @file,
                                                 keys: @thumbnail_size_keys,
                                                 include_doader: @updated_thumbnails_crop)
      end
    end

    def image_data
      if main_preview?
        stimulus_target("thumbImage")
      else
        stimulus_thumbnail(src: image_url)
      end
    end

    def render_thumb_image?
      image_url.present? || pending_preview_candidates.present?
    end

    # Inline aspect-ratio for the tile box so a 16:9 crop renders wide and a
    # 3:4 crop tall, at a fixed height (set in CSS).
    def thumb_style
      width, height = @ratio.split(":", 2).map(&:to_i)
      return "" if width.zero? || height.zero?

      "aspect-ratio: #{width} / #{height};"
    end

    def detail?
      @variant == :detail
    end

    def display_group_label
      @group_label.presence || " "
    end

    def modal_buttons
      render(Folio::Console::Ui::ButtonsComponent.new(
        class_name: "f-c-files-show-thumbnails-crop-edit__buttons",
        centered: true,
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

    def overlay_data
      stimulus_data(target: "overlay",
                    action: {
                      cancel: "cancelEditing",
                      click: "cancelEditingFromBackdrop",
                      pointerdown: "trackBackdropPointerDown",
                      pointerup: "trackBackdropPointerUp",
                    })
    end

    def data
      stimulus_controller("f-c-files-show-thumbnails-crop-edit",
                          values: stimulus_values,
                          action: {
                            "f-thumbnail:newData" => "thumbnailUpdated",
                            "f-c-files-show-thumbnails-crop-edit:preview-ready" => "thumbnailUpdated",
                          })
    end

    def stimulus_values
      values = {
        state: waiting_for_thumbnail? ? "waiting-for-thumbnail" : "viewing",
        cropper_data: cropper_data.to_json,
        api_url: url_for([:console, :api, @file, action: :update_thumbnails_crop]),
        api_data: api_data.to_json,
      }

      return values unless main_preview?

      values.merge(file_id: @file.id.to_s,
                   preview_candidates: preview_candidates.to_json,
                   preview_priority: main_preview_priority,
                   **preview_crop_stimulus_value)
    end

    def waiting_for_thumbnail?
      return @updated_thumbnails_crop unless main_preview?

      main_preview_size_key.nil? && pending_preview_candidates.present?
    end

    def preview_candidates
      return [] unless main_preview?

      @preview_candidates ||= ranked_main_preview_size_keys.each_with_index.map do |key, priority|
        { size: key, priority:, pending: thumbnail_pending?(key) }
      end
    end

    def pending_preview_candidates
      preview_candidates.select do |candidate|
        candidate[:pending] && candidate[:priority] < main_preview_priority
      end
    end

    def preview_crop_stimulus_value
      crop = configured_crop_position
      crop ? { preview_crop: crop.to_json } : {}
    end

    def main_preview_priority
      @main_preview_priority ||= main_preview_size_key ? ranked_main_preview_size_keys.index(main_preview_size_key) : ranked_main_preview_size_keys.length
    end

    def main_preview_size_key
      return @main_preview_size_key if defined?(@main_preview_size_key)

      @main_preview_size_key = ranked_main_preview_size_keys.find { |key| thumbnail_ready?(key) }
    end

    def ranked_main_preview_size_keys
      @ranked_main_preview_size_keys ||= representative_image.ranked_thumbnail_size_keys(
        main_preview_candidate_size_keys,
        preferred_ratio: @ratio,
        minimum_width: main_preview_width,
        minimum_height: MAIN_PREVIEW_HEIGHT,
      )
    end

    def main_preview_candidate_size_keys
      exact_ratio_keys = @thumbnail_size_keys.select do |key|
        representative_image.thumbnail_size_key_ratio(key) == @ratio
      end

      exact_ratio_keys.presence || @thumbnail_size_keys
    end

    def main_preview_width
      width, height = @ratio.split(":", 2).map(&:to_f)
      return MAIN_PREVIEW_HEIGHT unless width.positive? && height.positive?

      (MAIN_PREVIEW_HEIGHT * width / height).ceil
    end

    def resolved_main_preview_url
      return unless main_preview_size_key

      representative_image.resolved_thumbnail_url(file: @file, key: main_preview_size_key)
    end

    def thumbnail_ready?(key)
      url = thumbnail_url(key)
      url.present? && !url.include?("doader.com")
    end

    def thumbnail_pending?(key)
      thumbnail_url(key)&.include?("doader.com")
    end

    def thumbnail_url(key)
      thumbnail = @file.thumbnail_sizes[key]
      return unless thumbnail.is_a?(Hash)

      thumbnail[:url] || thumbnail["url"]
    end

    def main_preview?
      @group_type == "main_crop"
    end

    def representative_image
      Folio::Console::Files::Show::Thumbnails::RepresentativeImage
    end

    def cropper_data
      {
        aspect_ratio: cropper_aspect_ratio,
        **(configured_crop_position || gravity_crop_position),
      }
    end

    def configured_crop_position
      crop = @file.thumbnail_configuration&.dig("ratios", @ratio, "crop") || {}
      stored_crop_position(crop)
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
