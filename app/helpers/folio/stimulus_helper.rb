# frozen_string_literal: true

module Folio::StimulusHelper
  def stimulus_controller(*controller_names, values: {}, action: nil)
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

    h
  end

  def stimulus_data(action: nil, target: nil)
    fail "Missing @stimulus_controller_name" if @stimulus_controller_name.nil?

    h = {}

    if action
      if action.is_a?(String)
        h["action"] = "#{@stimulus_controller_name}##{action}"
      else
        action.each do |trigger, action_s|
          str = "#{trigger}->#{@stimulus_controller_name}##{action_s}"

          if h["action"]
            h["action"] += " #{str}"
          else
            h["action"] = str
          end
        end
      end
    end

    if target
      h["#{@stimulus_controller_name}-target"] = target
    end

    h
  end

  def stimulus_action(action)
    stimulus_data(action:)
  end

  def stimulus_target(target)
    stimulus_data(target:)
  end

  def stimulus_modal_toggle(target, dialog: nil)
    stimulus_controller("f-modal-toggle",
                        values: { target:, dialog: },
                        action: { click: "click" })
  end
end
