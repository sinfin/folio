# frozen_string_literal: true

class Folio::Atoms::FlashTriggerForBrokenComponent < ApplicationComponent
  def initialize(record: nil, broken_atoms_data: nil)
    @record = record
    @broken_atoms_data = broken_atoms_data
  end

  def render?
    return false if @record.blank?
    return false if @broken_atoms_data.blank?
    return false unless Folio::Current.ability.can?(:edit, @record)
    true
  end
end
