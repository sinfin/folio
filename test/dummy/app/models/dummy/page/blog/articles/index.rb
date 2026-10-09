# frozen_string_literal: true

class Dummy::Page::Blog::Articles::Index < Folio::Page
  include Folio::PerSiteSingleton

  def self.public_rails_path
    :dummy_blog_articles_path
  end

  def self.atoms_settings_skip_label_and_perex?
    true
  end
end
