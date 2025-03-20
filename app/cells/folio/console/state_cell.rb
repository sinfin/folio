# frozen_string_literal: true

class Folio::Console::StateCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  class_name "f-c-state", :small, :remote

  def show
    render if model.aasm_state.present?
  end

  def state
    @state ||= model.current_state_aasm_object
  end

  def state_square_tag(s, color)
    content_tag(:span, "", class: "f-c-state__state-square "\
                                  "f-c-state__state-square--color-#{color} "\
                                  "f-c-state__state-square--state-#{s.name} "\
                                  "f-c-state__state-square--model-#{model.class.table_name}")
  end

  def state_square(s = nil)
    s ||= state
    color = s.options[:color].presence || "default"
    state_square_tag(s, color)
  end

  def event_square(event)
    s = target_state(event)
    color = event.options[:color] || s.options[:color].presence || "default"
    state_square_tag(s, color)
  end

  def states
    @states ||= model.aasm.states.map do |state|
      {
        name: state.name,
        human_name: state.human_name,
        color: state.options.color.presence || "default",
      }
    end
  end

  def events(*args)
    @events ||= model.allowed_events_for(Folio::Current.user, *args)
  end

  def form(&block)
    opts = {
      method: :post,
      url: options[:url] || url_for([:event, :console, model]),
    }
    simple_form_for "", opts, &block
  end

  def target_state(event)
    to = event.transitions.first.to

    if to.is_a?(Array)
      to = model.try(:previous_aasm_state).try(:to_sym) || to.first
    end

    model.aasm.state_object_for_name(to)
  end

  def active?
    options[:active] != false && model.persisted?
  end

  def confirm(event)
    if event.options[:confirm]
      event.options[:confirm].is_a?(String) ? event.options[:confirm] : t("folio.console.confirmation")
    end
  end

  def remote_url_for(event)
    controller.folio.event_console_api_aasm_path(klass:,
                                                 id: model.id,
                                                 aasm_event: event.name,
                                                 reload_form: options[:reload_form] == true,
                                                 cell_options: {
                                                   active: options[:active],
                                                   remote: options[:remote],
                                                   small: options[:small],
                                                   button: options[:button],
                                                 })
  end

  def klass
    @klass ||= model.class.to_s
  end

  def event_target_human_name(event)
    to = event.transitions[0].to
    state = event.state_machine.states.find { |s| s.name == to }
    state ? state.human_name : to
  end

  def data
    stimulus_controller("f-c-state",
                        values: {
                          reload_form: options[:reload_form] == true,
                        })
  end

  def data_for_event(event)
    raise "FIXME Not implemented yet" if event.options[:email_modal]

    {
      "confirmation" => confirm(event),
      "url" => remote_url_for(event),
      "aasm-email-modal" => event.options[:email_modal],
      "modal-url" => event.options[:modal] ? controller.send(event.options[:modal][:path_name], model, _ajax: "1") : nil,
      "modal-title" => event.options[:modal] ? t("folio.console.form_modal_component.title/state") : nil,
      "event-name" => event.name,
      "event-target-human-name" => event_target_human_name(event),
      "klass" => klass,
      "id" => model.id,
      "email" => model.try(:email),
      "email-subject" => model.try(:aasm_email_default_subject, event) || model.class.try(:aasm_email_default_subject, event),
      "email-text" => model.try(:aasm_email_default_text, event) || model.class.try(:aasm_email_default_text, event),
    }.compact.merge(stimulus_action(click: "onTriggerClick"))
  end

  def button_class_names
    return if options[:button].blank?
    "btn btn-tertiary text-dark-gray"
  end
end
