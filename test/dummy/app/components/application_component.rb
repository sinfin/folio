# frozen_string_literal: true

class ApplicationComponent < Folio::ApplicationComponent
  include Dummy::UiHelper

  %i[
    cache_key_base
    current_user
    user_signed_in?
    current_header_menu
    current_footer_menu
  ].each do |name|
    define_method(name) do
      controller.try(name)
    end
  end

  def current_page_singleton(klass, fail_on_missing: false)
    controller.try(:current_page_singleton, klass, fail_on_missing:)
  end

  if ::Rails.env.test?
    def cache_key_base
      []
    end
  end
end
