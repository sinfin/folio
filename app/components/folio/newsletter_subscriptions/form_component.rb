# frozen_string_literal: true

class Folio::NewsletterSubscriptions::FormComponent < Folio::ApplicationComponent
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  bem_class_name :persisted, :invalid

  def initialize(newsletter_subscription: nil, view_options: {})
    @newsletter_subscription = newsletter_subscription || Folio::NewsletterSubscription.new
    @view_options = view_options
    @persisted = @newsletter_subscription.persisted?
    @invalid = @newsletter_subscription.errors.present?
  end

  def form(&block)
    opts = {
      url: controller.folio.folio_api_newsletter_subscriptions_path,
      html: {
        class: "f-newsletter-subscriptions-form__form",
        id: nil,
        data: stimulus_action("onSubmit")
      },
    }

    simple_form_for(@newsletter_subscription, opts, &block)
  end

  def submit_text
    return nil if @view_options[:submit_text] == false
    return @view_options[:submit_text] unless @view_options[:submit_text].nil?
    t(".submit")
  end

  def application_namespace
    @view_options[:application_namespace].presence || Rails.application.class.name.deconstantize
  end

  def submit_button
    klass = "#{application_namespace}::Ui::ButtonComponent".safe_constantize

    if klass
      render(klass.new(tag: :button,
                       label: submit_text,
                       variant: :primary,
                       type: :submit,
                       class_name: "f-newsletter-subscriptions-form__btn",
                       right_icon: @view_options[:submit_icon].present? ? @view_options[:submit_icon] : nil,
                       icon_height: @view_options[:submit_icon_height].presence || 24))
    else
      content_tag(:button,
                  submit_text,
                  class: "btn btn-primary f-newsletter-subscriptions-form__btn",
                  type: "submit")
    end
  end

  def message
    return @view_options[:message] unless @view_options[:message].nil?
    t(".message")
  end

  def placeholder
    return @view_options[:placeholder] unless @view_options[:placeholder].nil?
    t(".placeholder")
  end

  def input(f)
    f.input :email,
            as: :email,
            label: false,
            placeholder:,
            input_html: { class: "f-newsletter-subscriptions-form__input", id: nil },
            wrapper_html: { class: "f-newsletter-subscriptions-form__group" }
  end

  def data
    stimulus_controller("f-newsletter-subscriptions-form",
                        classes: %w[submitting persisted invalid])
  end

  def remember_option_keys
    [:placeholder, :submit_text, :message, :button_class, :input_label]
  end
end
