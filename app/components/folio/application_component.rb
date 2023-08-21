# frozen_string_literal: true

class Folio::ApplicationComponent < ViewComponent::Base
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
        if try(key)
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
end
