# frozen_string_literal: true

class Folio::ApplicationComponent < ViewComponent::Base
  include Folio::CstypoHelper
  include Folio::StimulusHelper

  def initialize(**kwargs)
    kwargs.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def original_bem_class_name
    base = self.class.name.delete_suffix("Component")

    if base.start_with?("Folio::Console::Auctify::")
      letters = "f-c-a"
      rest = base.gsub("Folio::Console::Auctify::", "")
    elsif base.start_with?("Folio::Console::Boutique::")
      letters = "f-c-b"
      rest = base.gsub("Folio::Console::Boutique::", "")
    elsif base.start_with?("Folio::Console::")
      letters = "f-c"
      rest = base.gsub("Folio::Console::", "")
    else
      namespace, rest = base.split("::", 2)
      letters = namespace[0].downcase
    end

    "#{letters}-#{rest.underscore.tr('/', '-').tr('_', '-')}"
  end

  def bem_class_name
    original_bem_class_name
  end

  def self.bem_class_name(*keys, base: nil)
    define_method :bem_class_name do
      base ||= original_bem_class_name

      class_names = [base]

      keys.each do |key|
        safe_key = key.to_s.delete("?")

        if instance_variable_get("@#{safe_key}")
          css_key = safe_key.tr("_", "-")
          class_names << "#{base}--#{css_key}"
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
