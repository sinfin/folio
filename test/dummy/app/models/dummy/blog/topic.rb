# frozen_string_literal: true

class Dummy::Blog::Topic < ApplicationRecord
  include Folio::BelongsToSiteAndFriendlyId
  include Folio::HasAttachments
  include Folio::Positionable
  include Folio::Publishable::Basic

  has_many :topic_article_links, -> { ordered },
                                    class_name: "Dummy::Blog::TopicArticleLink",
                                    inverse_of: :topic,
                                    foreign_key: :dummy_blog_topic_id,
                                    dependent: :destroy

  accepts_nested_attributes_for :topic_article_links, allow_destroy: true,
                                                         reject_if: :all_blank

  has_many :articles, through: :topic_article_links,
                      source: :article

  has_many :published_articles, -> { published },
                                through: :topic_article_links,
                                source: :article

  validates :locale,
            inclusion: { in: Dummy::Blog.available_locales }

  validates :title,
            presence: true,
            uniqueness: { scope: %i[site_id locale] }

  validate :validate_matching_locales_and_sites

  pg_search_scope :by_query,
                  against: {
                    title: "A",
                    perex: "B"
                  },
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  multisearchable against: [:title],
                  ignoring: :accents

  scope :by_locale, -> (locale) { where(locale:) }
  scope :featured, -> { where(featured: true) }
  scope :by_atom_setting_locale, -> (locale) { by_locale(locale) }

  scope :with_published_articles, -> { joins(:published_articles).distinct }

  def self.pregenerated_thumbnails
    h = {
      "Folio::FilePlacement::Cover" => [
        Folio::OG_IMAGE_DIMENSIONS,
        Folio::CellLightbox::LIGHTBOX_SIZE,
      ],
    }

    [].uniq.each do |size|
      h["Folio::FilePlacement::Cover"] << size
      h["Folio::FilePlacement::Cover"] << size.gsub(/\d+/) { |n| n.to_i * 2 }
    end

    h["Folio::FilePlacement::Cover"] = h["Folio::FilePlacement::Cover"].uniq

    h
  end

  private
    def validate_matching_locales_and_sites
      if locale_changed? && articles.where.not(locale:).exists?
        errors.add(:locale, :articles_have_different_locale)
      end

      if site_id_changed? && articles.where.not(site_id:).exists?
        errors.add(:site, :articles_have_different_site)
      end
    end
end

# == Schema Information
#
# Table name: dummy_blog_topics
#
#  id               :bigint(8)        not null, primary key
#  title            :string
#  slug             :string
#  perex            :text
#  locale           :string           default("cs")
#  published        :boolean
#  featured         :boolean
#  articles_count   :integer          default(0)
#  position         :integer
#  meta_title       :string
#  meta_description :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_dummy_blog_topics_on_featured   (featured)
#  index_dummy_blog_topics_on_locale     (locale)
#  index_dummy_blog_topics_on_position   (position)
#  index_dummy_blog_topics_on_published  (published)
#  index_dummy_blog_topics_on_slug       (slug)
#
