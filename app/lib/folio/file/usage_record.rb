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
    record = record.placement if record.is_a?(Folio::FilePlacement::Base)
    record = record.placement if record.is_a?(Folio::Atom::Base)
    return unless record.try(:persisted?)
    return unless record.respond_to?(:published)

    record.to_sgid(for: SGID_PURPOSE, expires_in: nil).to_s
  end

  def self.from_param(sgid, user: Folio::Current.user, ability: Folio::Current.ability)
    return unless sgid.is_a?(String) && sgid.present?
    return unless user && ability

    record = GlobalID::Locator.locate_signed(sgid, for: SGID_PURPOSE)
    return unless record
    return if record.respond_to?(:site_id) && record.site_id != Folio::Current.site&.id
    return unless user.can_now_by_ability?(ability, :update, record)

    new(record, sgid:)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def initialize(record, sgid: nil)
    @record = record
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

  private
    # Mirrors Folio::FilePlacement::Base#validate_usage_limit_if_published_placement,
    # which skips the usage limit for files already placed in a published record.
    def published?
      record.respond_to?(:published) && record.published == true
    end

    def placements
      placement_type = record.class.base_class.name
      direct_placements = Folio::FilePlacement::Base.where(placement_type:,
                                                           placement_id: record.id)
      atom_ids = Folio::Atom::Base.where(placement_type:,
                                         placement_id: record.id)
      atom_placements = Folio::FilePlacement::Base.where(placement_type: "Folio::Atom::Base",
                                                         placement_id: atom_ids.select(:id))

      direct_placements.or(atom_placements)
    end
end
