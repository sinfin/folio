# frozen_string_literal: true

module Dummy::Blog
  def self.table_name_prefix
    "dummy_blog_"
  end

  def self.available_locales
    I18n.available_locales.map(&:to_s)
  end
end
