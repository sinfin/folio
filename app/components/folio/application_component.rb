# frozen_string_literal: true

class Folio::ApplicationComponent < ViewComponent::Base
  include Folio::CstypoHelper
  include Folio::FormsHelper
  include Folio::IconHelper
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

  def atom_cover_placement(atom = nil)
    atom ||= @atom

    if atom
      if @atom_options
        if !@atom_options[:console_preview] && @atom_options[:cover_placements].present?
          return @atom_options[:cover_placements][atom.id]
        end
      end

      atom.cover_placement
    end
  end

  def current_user
    controller.try(:current_user)
  end

  def user_signed_in?
    controller.try(:user_signed_in?)
  end

  def current_user_with_test_fallback
    if Rails.env.test? && @current_user_for_test
      @current_user_for_test
    else
      Folio::Current.user
    end
  end

  def true_user_with_test_fallback
    if Rails.env.test?
      if @true_user_for_test
        @true_user_for_test
      else
        begin
          controller.try(:true_user)
        rescue StandardError
        end
      end
    else
      controller.try(:true_user)
    end
  end

  def can_now?(action, object = nil)
    controller.can_now?(action, object)
  end

  def adaptive_font_size_class_name(string)
    return string unless string.is_a?(String)

    if string.length <= 25
      "fs-adaptive fs-adaptive--large"
    elsif string.length <= 70
      "fs-adaptive fs-adaptive--medium"
    else
      "fs-adaptive fs-adaptive--small"
    end
  end
end
