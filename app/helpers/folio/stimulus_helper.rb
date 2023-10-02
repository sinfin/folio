# frozen_string_literal: true

module Folio::StimulusHelper
  def stimulus_controller(*controller_names, values: {}, action: nil, classes: [])
    @stimulus_controller_name = controller_names.first

    h = {
      "controller" => controller_names.join(" "),
    }

    values.each do |key, value|
      value = value.to_s if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      h["#{@stimulus_controller_name}-#{key}-value"] = value
    end

    if action
      h = h.merge(stimulus_action(action))
    end

    if classes
      h = h.merge(stimulus_classes(classes))
    end

    h
  end

  def stimulus_data(action: nil, target: nil, controller: nil, classes: [])
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

    if classes.present?
      classes.each do |class_name|
        h["#{controller}-#{class_name}-class"] = "#{original_bem_class_name}--#{class_name}"
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

  def stimulus_modal_toggle(target, dialog: nil)
    stimulus_controller("f-modal-toggle",
                        values: { target:, dialog: },
                        action: { click: "click" })
  end
end
