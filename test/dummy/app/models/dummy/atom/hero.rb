# frozen_string_literal: true

class Dummy::Atom::Hero < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    perex: :text,
    primary_button_url: :string,
    primary_button_label: :string,
    secondary_button_url: :string,
    secondary_button_label: :string,
    color: %w[light dark],
  }

  ASSOCIATIONS = {}

  validate :validate_at_least_one
  validate :validate_urls_if_labels_are_present

  def self.molecule_cell_name
    "dummy/molecule/hero"
  end

  def self.console_icon
    :star
  end

  def self.console_insert_row
    2
  end

  def color_with_fallback
    color.presence || self.class::STRUCTURE[:color].first
  end

  private
    def validate_at_least_one
      filled = false

      self.class::STRUCTURE.keys.each do |key|
        filled = filled || send(key).present?
      end

      unless filled
        errors.add(:base, :at_least_one)
      end
    end

    def validate_urls_if_labels_are_present
      %i[primary secondary].each do |key|
        if send("#{key}_button_label").present?
          if send("#{key}_button_url").blank?
            errors.add("#{key}_button_url", :blank)
          end
        end
      end
    end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id              :bigint(8)        not null, primary key
#  type            :string
#  position        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  placement_type  :string
#  placement_id    :bigint(8)
#  locale          :string
#  data            :jsonb
#  associations    :jsonb
#  data_for_search :text
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
