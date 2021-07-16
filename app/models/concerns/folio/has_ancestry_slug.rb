# frozen_string_literal: true

module Folio::HasAncestrySlug
  extend ActiveSupport::Concern

  included do
    before_validation :set_ancestry_slug
    after_save :update_children_ancestry_slugs!
    after_destroy :update_children_ancestry_slugs!
  end

  def ancestry_slug
    super || begin
      if root?
        nil
      else
        url = parent.ancestry_url
        update_column(:ancestry_slug, url || "")
        url
      end
    end
  end

  def ancestry_url
    if ancestry_slug.present?
      "#{ancestry_slug}/#{slug}"
    else
      slug
    end
  end

  def set_ancestry_slug
    self.ancestry_slug = self.parent.try(:ancestry_url) || ""
  end

  def update_ancestry_slug!
    set_ancestry_slug
    save!
  end

  def update_children_ancestry_slugs!(force: false)
    return if new_record?

    if destroyed?
      self.class.base_class.where("ancestry_slug LIKE ?", "#{slug}%").each do |record|
        record.update_ancestry_slug!
      end
    elsif force || saved_change_to_slug? || saved_change_to_ancestry?
      if children?
        children.each do |c|
          c.update_ancestry_slug!
          c.update_children_ancestry_slugs!(force: true)
        end
      end
    end
  end
end
