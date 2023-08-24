# frozen_string_literal: true

class Folio::ApplicationComponent < ViewComponent::Base
  include Folio::CstypoHelper

  def original_bem_class_name
    namespace, rest = self.class.name.delete_suffix("Component").split("::", 2)
    "#{namespace[0].downcase}-#{rest.underscore.tr('/', '-').tr('_', '-')}"
  end

  def bem_class_name
    original_bem_class_name
  end

  def self.bem_class_name(*keys)
    define_method :bem_class_name do
      base = original_bem_class_name

      class_names = [base]

      keys.each do |key|
        if instance_variable_get("@#{key}")
          safe_key = key.to_s.tr("_", "-").delete("?")
          class_names << "#{base}--#{safe_key}"
        end
      end

      class_names.join(" ")
    end
  end

  def url_for(options)
    controller.url_for(options)
  rescue NoMethodError, ActionController::UrlGenerationError
    controller.main_app.url_for(options)
  end

  def menu_url_for(menu_item)
    if menu_item.url.present?
      menu_item.url
    elsif menu_item.eager_load_aware_target.present?
      url_for(menu_item.eager_load_aware_target)
    elsif menu_item.rails_path.present?
      begin
        controller.send(menu_item.rails_path)
      rescue NoMethodError, ActionController::UrlGenerationError
        controller.main_app.send(menu_item.rails_path)
      end
    end
  end

  def stimulus_controller(controller_name, values: {})
    @stimulus_controller_name = controller_name

    h = {
      "controller" => controller_name,
    }

    values.each do |key, value|
      value = value.to_s if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      h["#{controller_name}-#{key}-value"] = value
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
end
