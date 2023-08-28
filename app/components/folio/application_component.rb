# frozen_string_literal: true

class Folio::ApplicationComponent < ViewComponent::Base
  include Folio::CstypoHelper
  include Folio::StimulusHelper

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

  def current_site
    controller.current_site
  end
end
