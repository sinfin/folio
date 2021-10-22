# frozen_string_literal: true

module Folio::HasAncestrySlug
  extend ActiveSupport::Concern

  included do
    before_validation :set_ancestry_slugs
    after_save :update_children_ancestry_slugs!
    after_destroy :update_children_ancestry_slugs!
  end

  def ancestry_slug
    if self.class.ancestry_slug_columns.size > 1
      column_name = "ancestry_slug_#{I18n.locale}"
    else
      column_name = "ancestry_slug"
    end

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
    if self.class.ancestry_slug_columns.size > 1
      locale ||= I18n.locale
      ancestry_slug_column_name = "ancestry_slug_#{locale}"
      slug_column_name = "slug_#{locale}"
    else
      ancestry_slug_column_name = "ancestry_slug"
      slug_column_name = "slug"
    end

    if send(ancestry_slug_column_name).present?
      "#{send(ancestry_slug_column_name)}/#{send(slug_column_name)}"
    else
      send(slug_column_name)
    end
  end

  def set_ancestry_slugs
    self.class.ancestry_slug_columns.each do |ancestry_slug_column|
      if ancestry_slug_column == "ancestry_slug"
        self.send("#{ancestry_slug_column}=", self.parent.try(:ancestry_url) || "")
      else
        locale = ancestry_slug_column.delete_prefix("ancestry_slug_")
        self.send("#{ancestry_slug_column}=", self.parent.try(:ancestry_url, locale) || "")
      end
    end
  end

  def update_ancestry_slug!
    set_ancestry_slugs
    save!
  end

  def update_children_ancestry_slugs!(force: false)
    return if new_record?

    if destroyed?
      self.class.ancestry_slug_columns.each do |ancestry_slug_column|
        slug_column = ancestry_slug_column.delete_prefix("ancestry_")
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
    if self.class.ancestry_slug_columns.size > 1
      self.class.ancestry_slug_columns.any? do |key|
        locale = key.delete_prefix("ancestry_slug_")
        send("saved_change_to_slug_#{locale}?")
      end
    else
      super
    end
  end

  class_methods do
    def ancestry_slug_columns
      @ancestry_slug_columns ||= column_names.select { |column_name| column_name.start_with?("ancestry_slug") }
    end
  end
end
