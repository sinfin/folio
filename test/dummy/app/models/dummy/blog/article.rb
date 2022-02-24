# frozen_string_literal: true

class Dummy::Blog::Article < ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::Publishable::WithDate
  include Folio::HasAtoms::Basic

  has_many :topic_article_links, -> { ordered },
                                    class_name: "Dummy::Blog::TopicArticleLink",
                                    inverse_of: :article,
                                    foreign_key: :dummy_blog_article_id,
                                    dependent: :destroy

  accepts_nested_attributes_for :topic_article_links, allow_destroy: true,
                                                         reject_if: :all_blank

  has_many :topics, through: :topic_article_links, source: :topic
  has_many :published_topics, -> { published },
                              through: :topic_article_links,
                              source: :topic

  validates :title,
            :perex,
            presence: true

  validates :locale,
            inclusion: { in: Dummy::Blog.available_locales }

  validate :validate_matching_locales

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

  scope :ordered, -> { order(published_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :by_locale, -> (locale) { where(locale: locale) }

  scope :by_topic, -> (topic) do
    ids = Dummy::Blog::TopicArticleLink.select(:dummy_blog_article_id)
                                          .where(topic: topic)

    where(id: ids)
  end

  scope :by_topic_slug, -> (slug) do
    topic = Dummy::Blog::Topic.find_by(slug: slug)

    if topic
      by_topic(topic)
    else
      none
    end
  end

  def published_at_with_fallback
    published_at || created_at
  end

  def to_ui_article_meta
    {
      tag_records: published_topics,
      published_at: published_at_with_fallback,
    }
  end

  def to_ui_article_card_model
    to_ui_article_meta.merge(
      cover_placement: cover_placement,
      title: title,
      url_for_args: self,
      content: ActionController::Base.helpers.content_tag(:p, perex),
    )
  end

  def self.pregenerated_thumbnails
    h = {
      "Folio::FilePlacement::Cover" => [
        Folio::OG_IMAGE_DIMENSIONS,
        Folio::CellLightbox::LIGHTBOX_SIZE,
      ],
    }

    [
      Dummy::Blog::Articles::ShowHeaderCell::THUMB_SIZE,
      Dummy::Ui::ArticleCardCell::THUMB_SIZE,
    ].uniq.each do |size|
      h["Folio::FilePlacement::Cover"] << size
      h["Folio::FilePlacement::Cover"] << size.gsub(/\d+/) { |n| n.to_i * 2 }
    end

    h["Folio::FilePlacement::Cover"] = h["Folio::FilePlacement::Cover"].uniq

    h
  end

  def self.atom_settings_from_params(params)
    settings = {}

    if params[:title].present?
      params[:title].each do |locale, title|
        settings[locale] ||= []

        begin
          safe_published_at = Date.parse(params[:published_at][locale])
        rescue StandardError
          safe_published_at = nil
        end

        if params[:topics][locale].present?
          topics = Dummy::Blog::Topic.where(id: params[:topics][locale]).to_a

          # reorder
          tag_records = params[:topics][locale].map do |id|
            topics.find { |topic| topic.id == id }
          end.compact
        else
          tag_records = []
        end

        hash = {
          title: title,
          perex: params[:perex] && params[:perex][locale],
          cover_placement: params[:cover_placement] && Folio::FilePlacement::Cover.new(params[:cover_placement][locale].permit(:file_id, :alt)),
          to_ui_article_meta: {
            tag_records: tag_records,
            published_at: safe_published_at,
          }
        }

        settings[locale] << {
          cell_name: "dummy/blog/articles/show_header",
          model: OpenStruct.new(hash),
          key: :title,
        }
      end
    end

    settings
  end

  private
    def validate_matching_locales
      unless topic_article_links.all?(&:valid?)
        errors.delete("topic_article_links.base")
        errors.add(:locale, :doesnt_match_topics)
      end
    end
end

# == Schema Information
#
# Table name: dummy_blog_articles
#
#  id               :bigint(8)        not null, primary key
#  title            :string
#  slug             :string
#  perex            :text
#  locale           :string           default("cs")
#  meta_title       :string
#  meta_description :text
#  featured         :boolean
#  published        :boolean
#  published_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_dummy_blog_articles_on_featured      (featured)
#  index_dummy_blog_articles_on_locale        (locale)
#  index_dummy_blog_articles_on_published     (published)
#  index_dummy_blog_articles_on_published_at  (published_at)
#  index_dummy_blog_articles_on_slug          (slug)
#