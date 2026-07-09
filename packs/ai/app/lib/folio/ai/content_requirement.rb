# frozen_string_literal: true

# Evaluates record-wide source-content requirements before provider requests run.
class Folio::Ai::ContentRequirement
  STRUCTURAL_KEYS = %w[
    _destroy
    active
    file_id
    id
    locale
    placement_id
    placement_type
    position
    record_id
    selected_at
    type
    version
  ].freeze

  def self.satisfied?(record:, requirement:, form_snapshot:)
    new(record:, requirement:, form_snapshot:).satisfied?
  end

  def initialize(record:, requirement:, form_snapshot:)
    @record = record
    @requirement = requirement&.to_sym
    @form_snapshot = form_snapshot.to_h.stringify_keys
  end

  def satisfied?
    return true if requirement.blank?

    case requirement
    when :tiptap_or_atoms
      tiptap_or_atoms_content_present?
    else
      false
    end
  end

  private
    attr_reader :record,
                :requirement,
                :form_snapshot

    def tiptap_or_atoms_content_present?
      body_roots.any? { |root| usable_value?(form_snapshot[root]) }
    end

    def body_roots
      @body_roots ||= (tiptap_roots + atom_attribute_roots).uniq
    end

    def tiptap_roots
      return [] unless record.class.respond_to?(:folio_tiptap_fields)

      record.class.folio_tiptap_fields.map(&:to_s)
    end

    def atom_attribute_roots
      return [] unless record.class.respond_to?(:atom_keys)

      record.class.atom_keys.map { |key| "#{key}_attributes" }
    end

    def usable_value?(value, key: nil)
      return false if structural_key?(key)

      case value
      when Hash
        value.any? { |child_key, child_value| usable_value?(child_value, key: child_key) }
      when Array
        value.any? { |child_value| usable_value?(child_value) }
      else
        value.to_s.strip.present?
      end
    end

    def structural_key?(key)
      STRUCTURAL_KEYS.include?(key.to_s)
    end
end
