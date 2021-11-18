# frozen_string_literal: true

class Folio::Console::StateCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  class_name "f-c-state", :small, :remote

  def show
    render if model.aasm_state.present?
  end

  def state
    @state ||= model.aasm.state_object_for_name(model.aasm_state.to_sym)
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

  def events
    @events ||= model.aasm.events(permitted: true)
                          .reject { |e| e.options[:private] }
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
    options[:active] != false
  end

  def confirm(event)
    if event.options[:confirm]
      event.options[:confirm].is_a?(String) ? event.options[:confirm] : t("folio.console.confirmation")
    end
  end

  def remote_url_for(event)
    controller.folio.event_console_api_aasm_path(klass: klass,
                                                 id: model.id,
                                                 aasm_event: event.name,
                                                 cell_options: {
                                                   active: options[:active],
                                                   remote: options[:remote],
                                                   small: options[:small],
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
end
