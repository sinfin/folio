# frozen_string_literal: true

class Folio::Users::ImpersonatingBarComponent < Folio::ApplicationComponent
  def initialize(current_user_for_test: nil, true_user_for_test: nil)
    @current_user_for_test = current_user_for_test
    @true_user_for_test = true_user_for_test
  end

  def render?
    current_user_with_test_fallback && impersonating_in_progress?
  end

  def impersonating_in_progress?
    true_user_with_test_fallback && current_user_with_test_fallback != true_user_with_test_fallback
  end

  def href
    controller.folio.url_for([:stop_impersonating, :console, Folio::User])
  end

  def label
    t(".label",
      true_user: true_user_with_test_fallback.to_label,
      impersonated_user: current_user_with_test_fallback.to_label)
  end

  def stop_link
    link_to(t(".stop_impersonation"),
            href,
            data: { turbo: false })
  end

  def alert_component
    klass = "#{::Rails.application.class.name.deconstantize}::Ui::AlertComponent".safe_constantize

    if klass
      klass.new(icon: :user,
                variant: :danger,
                closable: false,
                margin: false)
    end
  end
end
