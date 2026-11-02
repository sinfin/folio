# frozen_string_literal: true

# The record a console file picker selects files for. A file already placed in
# a published record does not consume another usage when the record uses it
# again, so pickers let editors select it despite an exhausted usage limit.
class Folio::File::UsageRecord
  PARAM = :usage_record
  SGID_PURPOSE = "folio_file_usage_record"

  attr_reader :record

  # Accepts the record itself, one of its file placements or one of its atoms.
  def self.sgid_for(record)
    record = record_for(record)
    return unless record.try(:persisted?)
    return unless record.respond_to?(:published)

    record.to_sgid(for: SGID_PURPOSE, expires_in: nil).to_s
  end

  def self.parent_reflection_for(klass)
    association = klass.try(:folio_file_usage_parent_association)
    klass.reflect_on_association(association) if association
  end

  def self.record_for(record)
    record = record.placement if record.is_a?(Folio::FilePlacement::Base)
    record = record.placement if record.is_a?(Folio::Atom::Base)
    reflection = parent_reflection_for(record.class)
    reflection ? record.public_send(reflection.name) : record
  end

  def self.from_param(sgid, user: Folio::Current.user, ability: Folio::Current.ability)
    return unless sgid.is_a?(String) && sgid.present?
    return unless user && ability

    record = record_for(GlobalID::Locator.locate_signed(sgid, for: SGID_PURPOSE))
    return unless record
    return if record.respond_to?(:site_id) && record.site_id != Folio::Current.site&.id
    return unless user.can_now_by_ability?(ability, :update, record)

    new(record, sgid:)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def initialize(record, sgid: nil)
    @record = self.class.record_for(record)
    @sgid = sgid
  end

  def sgid
    @sgid ||= self.class.sgid_for(record)
  end

  def reuses?(file)
    file.is_a?(Folio::File) && reusable_file_ids.include?(file.id)
  end

  def reusable_file_ids
    @reusable_file_ids ||= if published?
      placements.distinct.pluck(:file_id)
    else
      []
    end
  end

  def placements
    return Folio::FilePlacement::Base.none unless record.try(:persisted?)

    placements_for(klass: record.class, ids: record.id).or(child_placements)
  end

  def child_placements
    placements = Folio::FilePlacement::Base.none
    return placements unless record.try(:persisted?)

    Array(record.class.try(:folio_file_usage_child_associations)).each do |association|
      children = record.public_send(association)
      children = children.where(published: true) if children.klass.column_names.include?("published")
      placements = placements.or(placements_for(klass: children.klass, ids: children.select(:id)))
    end

    placements
  end

  private
    # Mirrors Folio::FilePlacement::Base#validate_usage_limit_if_published_placement,
    # which skips the usage limit for files already placed in a published record.
    def published?
      record.try(:persisted?) && record.try(:published) == true &&
        record.class.where(id: record.id, published: true).exists?
    end

    def placements_for(klass:, ids:)
      placement_type = klass.base_class.name
      direct_placements = Folio::FilePlacement::Base.where(placement_type:,
                                                           placement_id: ids)
      atom_ids = Folio::Atom::Base.where(placement_type:,
                                         placement_id: ids)
      atom_placements = Folio::FilePlacement::Base.where(placement_type: "Folio::Atom::Base",
                                                         placement_id: atom_ids.select(:id))

      direct_placements.or(atom_placements)
    end
end
