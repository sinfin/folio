# frozen_string_literal: true

class Dummy::Ui::RecordBarComponent < ApplicationComponent
  def initialize(record:)
    @record = record
  end

  def render?
    return false if @record.blank?
    return false unless Folio::Current.ability && Folio::Current.ability.can?(:edit, @record)
    return false unless console_edit_href
    true
  end

  def buttons
    ary = [{
      href: console_edit_href,
      label: "<span class=\"d-sm-none\">#{t(".edit_mobile")}</span><span class=\"d-none d-sm-inline\">#{t(".edit_desktop")}</span>".html_safe,
      size: :sm,
      icon: :edit,
      variant: :tertiary,
      target: "_blank",
      data: { turbolinks: "false" }
    }]

    if controller.instance_variable_get(Folio::AtomsHelper::BROKEN_DATA_KEY).present?
      ary << {
        href: console_edit_href,
        size: :sm,
        icon: :alert_triangle,
        label: "<span class=\"d-sm-none\">#{t(".broken_atom_mobile")}</span><span class=\"d-none d-sm-inline\">#{t(".broken_atom_desktop")}</span>".html_safe,
        variant: :danger,
        target: "_blank",
        data: { turbolinks: "false" }
      }
    end

    ary
  end

  def console_edit_href
    @console_edit_href ||= begin
      url_for([:edit, :console, @record])
    rescue StandardError
      controller.folio.url_for([:edit, :console, @record])
    end
  rescue StandardError
    nil
  end
end
