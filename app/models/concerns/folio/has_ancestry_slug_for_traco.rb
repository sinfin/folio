# frozen_string_literal: true

module Folio::HasAncestrySlugForTraco
  extend ActiveSupport::Concern

  included do
    before_validation :set_ancestry_slugs
    after_save :update_children_ancestry_slugs!
    after_destroy :update_children_ancestry_slugs!
  end

  def ancestry_slug
    column_name = "ancestry_slug_#{I18n.locale}"

    self[column_name] || begin
      if root?
        nil
      else
        url = parent.ancestry_url
        update_column(column_name, url || "")
        url
      end
    end
  end

  def ancestry_url(locale = nil)
    locale ||= I18n.locale
    ancestry_slug_column_name = "ancestry_slug_#{locale}"
    slug_column_name = "slug_#{locale}"

    if send(ancestry_slug_column_name).present?
      "#{send(ancestry_slug_column_name)}/#{send(slug_column_name)}"
    else
      send(slug_column_name)
    end
  end

  def set_ancestry_slugs
    I18n.available_locales.each do |locale|
      ancestry_slug_column = "ancestry_slug_#{locale}"
      self.send("#{ancestry_slug_column}=", self.parent.try(:ancestry_url, locale) || "")
    end
  end

  def update_ancestry_slug!
    set_ancestry_slugs
    save!
  end

  def update_children_ancestry_slugs!(force: false)
    return if new_record?

    if destroyed?
      I18n.available_locales.each do |locale|
        ancestry_slug_column = "ancestry_slug_#{locale}"
        slug_column = "slug_#{locale}"
        self.class.base_class.where("#{ancestry_slug_column} LIKE ?", "#{send(slug_column)}%").each do |record|
          record.update_ancestry_slug!
        end
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

  def saved_change_to_slug?
    I18n.available_locales.any? do |locale|
      send("saved_change_to_slug_#{locale}?")
    end
  end
end
