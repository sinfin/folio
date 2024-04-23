# frozen_string_literal: true

module Folio::StimulusHelper
  LIGHTBOX_CONTROLLER = "f-lightbox"

  def stimulus_controller(*controller_names, values: {}, action: nil, params: nil, classes: [], outlets: [], inline: false)
    controller = controller_names.first

    unless inline
      @stimulus_controller_name = controller
    end

    h = {
      "controller" => controller_names.join(" "),
    }

    values.each do |key, value|
      value = value.to_s if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      h["#{controller}-#{key}-value"] = value
    end

    h.merge(stimulus_data(controller:, action:, outlets:, classes:, params:))
  end

  def stimulus_data(action: nil, target: nil, controller: nil, classes: [], outlets: [], params: nil)
    controller ||= @stimulus_controller_name
    fail "Missing @stimulus_controller_name" if controller.nil?

    h = {}

    if action
      if action.is_a?(String)
        if action.include?("#")
          h["action"] = action
        else
          h["action"] = "#{controller}##{action}"
        end
      else
        action.each do |trigger, action_s|
          str = "#{trigger}->#{controller}##{action_s}"

          if h["action"]
            h["action"] += " #{str}"
          else
            h["action"] = str
          end
        end
      end
    end

    if target
      h["#{controller}-target"] = target
    end

    if params.present?
      params.each do |param, value|
        value = value.to_s if value.is_a?(TrueClass) || value.is_a?(FalseClass)
        h["#{controller}-#{param}-param"] = value
      end
    end

    if classes.present?
      classes.each do |class_name|
        h["#{controller}-#{class_name}-class"] = "#{original_bem_class_name}--#{class_name}"
      end
    end

    if outlets.present?
      outlets.each do |class_name_same_as_controller_name|
        h["#{controller}-#{class_name_same_as_controller_name}-outlet"] = ".#{class_name_same_as_controller_name}"
      end
    end

    h
  end

  def stimulus_action(action)
    stimulus_data(action:)
  end

  def stimulus_target(target)
    stimulus_data(target:)
  end

  def stimulus_classes(classes)
    stimulus_data(classes:)
  end

  def stimulus_outlets(outlets)
    stimulus_data(outlets:)
  end

  def stimulus_lightbox
    stimulus_controller(LIGHTBOX_CONTROLLER, inline: true)
  end

  def stimulus_lightbox_item(placement_or_file, title: nil, cloned: false, index: nil)
    file = if placement_or_file.is_a?(Folio::FilePlacement::Base)
      placement_or_file.file
    else
      placement_or_file
    end

    thumb = file.thumb(Folio::LIGHTBOX_IMAGE_SIZE)

    {
      "action" => "click->f-lightbox#onItemClick",
      "f-lightbox-target" => cloned ? "clone" : "item",
      "f-lightbox-index" => index,
      "photoswipe" => {
        "src" => thumb.webp_url || thumb.url,
        "w" => thumb.width,
        "h" => thumb.height,
        "author" => file.try(:author).presence || "",
        "caption" => title || file.try(:description).presence || "",
      }.to_json
    }.compact
  end

  def stimulus_modal_toggle(target, dialog: nil)
    stimulus_controller("f-modal-toggle",
                        values: { target:, dialog: },
                        action: { click: "click" },
                        inline: true)
  end

  def stimulus_modal_close
    stimulus_controller("f-modal-close",
                        action: { click: "click" },
                        inline: true)
  end

  def stimulus_merge_data(*hashes)
    result = {}
    keys = %w[controller action]

    hashes.each do |hash|
      next if hash.blank?

      result = result.merge(hash.without(*keys))

      keys.each do |key|
        if result[key].present?
          if hash[key].present?
            result[key] += " #{hash[key]}"
          end
        elsif hash[key].present?
          result[key] = hash[key]
        end
      end
    end

    result
  end

  def stimulus_console_form_modal_trigger(url, title: "")
    stimulus_controller("f-c-form-modal-trigger",
                        values: { url:, title: },
                        action: { click: "click" },
                        inline: true)
  end
end
