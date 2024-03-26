# frozen_string_literal: true

class Folio::Console::OnboardingCell < Folio::ConsoleCell
  def show
    render if model.present? && steps.any? { |step, data| !data[:done] }
  end

  def steps
    @steps ||= begin
      has_undone = false
      hash = {}
      index = 0
      i18n_key_base = "folio.console.onboarding.steps.#{model.class.base_class}"

      model.class.folio_console_onboarding_steps.each do |step, data|
        done = !has_undone && data[:condition].call(model)
        disabled = has_undone

        has_undone = true unless done

        hash[step] = {
          number: index += 1,
          title: I18n.t("#{i18n_key_base}.#{step}.title"),
          text: I18n.t("#{i18n_key_base}.#{step}.text"),
          action: I18n.t("#{i18n_key_base}.#{step}.action"),
          url: disabled ? nil : data[:url].call(self),
          done:,
          disabled:
        }
      end

      hash
    end
  end

  def title_icon(data)
    if data[:done]
      folio_icon(:check_circle_outline,
                 class: "card-title-icon text-success")
    else
      folio_icon(:checkbox_blank_circle_outline,
                 class: "card-title-icon")
    end
  end

  def button(data)
    cell("folio/console/ui/button",
         class: "f-c-onboarding__btn",
         variant: (data[:done] || data[:disabled]) ? :secondary : :success,
         label: data[:action],
         disabled: data[:disabled],
         right_icon: data[:done] ? nil : :arrow_right,
         href: data[:url])
  end
end
