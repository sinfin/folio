# frozen_string_literal: true

class Folio::Atoms::FlashTriggerForBrokenComponent < ApplicationComponent
  def initialize(record: nil, broken_atoms_data: nil)
    @record = record
    @broken_atoms_data = broken_atoms_data
  end

  def render?
    return false if @record.blank?
    return false if @broken_atoms_data.blank?
    return false unless Folio::Current.ability && Folio::Current.ability.can?(:edit, @record)
    true
  end

  def data
    stimulus_controller("f-atoms-flash-trigger-for-broken",
                        values: {
                          application_namespace: ::Rails.application.class.name.deconstantize,
                          message:,
                        })
  end

  def message
    str = "<strong>#{t('.title')}</strong> #{t('.subtitle')}"

    @broken_atoms_data.each do |hash|
      str += "<br>"
      str += "#{hash[:atom].class.model_name.human} - " if hash[:atom]
      str += hash[:error].message
    end

    str
  end
end
