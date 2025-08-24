# frozen_string_literal: true

module Folio::BackwardCompatibleIptcMetadata
  extend ActiveSupport::Concern
  
  included do
    # Setup callbacks or validations if needed
    # Instance methods are defined outside of included block per Rails conventions
  end

  # Instance methods for backward compatibility
  # author field - backward compatibility with IPTC creator
  def author
    # Always return creator array joined with commas (primary IPTC source)
    return creator.join(", ") if creator.present? && creator.is_a?(Array) && creator.any?
    # Fallbacks for legacy data
    return self[:author] if has_attribute?(:author) && self[:author].present?
    return self[:author_legacy] if has_attribute?(:author_legacy) && self[:author_legacy].present?
    nil
  end
  
  def author=(value)
    # Set both old and new fields for maximum compatibility
    if has_attribute?(:author)
      self[:author] = value.present? ? value.to_s : nil
    end
    
    # Also update creator array for IPTC compliance - split by commas
    if has_attribute?(:creator)
      if value.present?
        # Split by commas and clean up whitespace
        creators = value.to_s.split(/[,;]/).map(&:strip).reject(&:blank?)
        self.creator = creators
      else
        self.creator = []
      end
    end
  end
  # alt field - backward compatibility
  def alt
    # Priority: new alt field > headline > legacy backup  
    return self[:alt] if has_attribute?(:alt) && self[:alt].present?
    return headline if has_attribute?(:headline) && headline.present?
    return self[:alt_legacy] if has_attribute?(:alt_legacy)
    nil
  end
  
  def alt=(value)
    # Set both fields for maximum compatibility
    if has_attribute?(:alt)
      self[:alt] = value.to_s if value.present?
    end
    
    # Also update headline for IPTC compliance
    if has_attribute?(:headline) && headline.blank?
      self.headline = value.to_s if value.present?
    end
  end
  
  # Legacy method aliases for existing applications
  def author_name
    author
  end
  
  def authors
    return creator if creator.present? && creator.is_a?(Array)
    return [author].compact if author.present?
    []
  end
  
  # Support both array and string access for keywords (backward compatibility)
  def keywords_string
    return keywords.join(", ") if keywords.present? && keywords.is_a?(Array)
    nil
  end
  
  def keywords_string=(value)
    if has_attribute?(:keywords)
      self.keywords = value.present? ? value.to_s.split(/[,;]/).map(&:strip).reject(&:blank?) : []
    end
  end
  
  # Legacy tag_list compatibility if not already defined
  def tag_list
    keywords_string if respond_to?(:keywords_string)
  end
  
  def tag_list=(value)
    self.keywords_string = value if respond_to?(:keywords_string=)
  end
  
  # Override JSONB field setters to ensure proper normalization
  def creator=(value)
    return write_attribute(:creator, []) if value.blank?
    
    normalized_value = case value
                      when Array 
                        value.map(&:to_s).compact.reject(&:blank?)
                      when String 
                        [value.to_s].reject(&:blank?)
                      else 
                        []
                      end
    
    write_attribute(:creator, normalized_value)
    
    # Also update legacy author field for backward compatibility
    if has_attribute?(:author) && normalized_value.any?
      self[:author] = normalized_value.first
    end
  end
  
  # Ensure keywords is always a proper JSONB array  
  def keywords=(value)
    return write_attribute(:keywords, []) if value.blank?
    
    normalized_value = case value
                      when Array 
                        value.map(&:to_s).compact.reject(&:blank?)
                      when String 
                        value.to_s.split(/[,;]/).map(&:strip).reject(&:blank?)
                      else 
                        []
                      end
    
    write_attribute(:keywords, normalized_value)
  end
  
  # Helper method to check if we have the new IPTC fields
  def has_iptc_metadata_fields?
    has_attribute?(:creator) && has_attribute?(:headline) && has_attribute?(:keywords)
  end
  
  # Migration helper - check if data needs to be migrated from legacy fields
  def needs_legacy_data_migration?
    return false unless has_iptc_metadata_fields?
    
    # Check if new fields are empty but legacy fields have data
    (creator.blank? && has_attribute?(:author_legacy) && self[:author_legacy].present?) ||
    (headline.blank? && has_attribute?(:alt_legacy) && self[:alt_legacy].present?)
  end
  
  class_methods do
    # Scope for finding files that need legacy data migration
    def needing_legacy_migration
      return none unless connection.column_exists?(:folio_files, :author_legacy) || connection.column_exists?(:folio_files, :alt_legacy)
      
      where(
        "(creator = '[]' OR creator IS NULL) AND author_legacy IS NOT NULL AND author_legacy != '' " \
        "OR (headline IS NULL OR headline = '') AND alt_legacy IS NOT NULL AND alt_legacy != ''"
      )
    end
    
    # Count files that need migration
    def legacy_migration_count
      needing_legacy_migration.count
    end
  end
end
