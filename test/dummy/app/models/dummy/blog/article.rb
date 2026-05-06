# frozen_string_literal: true

class Dummy::Blog::Article < ApplicationRecord
  include Folio::BelongsToSiteAndFriendlyId
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

  has_many :author_article_links, -> { ordered },
                                    class_name: "Dummy::Blog::AuthorArticleLink",
                                    inverse_of: :article,
                                    foreign_key: :dummy_blog_article_id,
                                    dependent: :destroy

  accepts_nested_attributes_for :author_article_links, allow_destroy: true,
                                                       reject_if: :all_blank

  has_many :authors, through: :author_article_links, source: :author

  has_many :published_authors, -> { published },
                              through: :author_article_links,
                              source: :author

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
  scope :by_locale, -> (locale) { where(locale:) }

  scope :by_topic, -> (topic) do
    ids = Dummy::Blog::TopicArticleLink.select(:dummy_blog_article_id)
                                          .where(topic:)

    where(id: ids)
  end

  scope :by_topic_slug, -> (slug) do
    topic = Dummy::Blog::Topic.find_by(slug:)

    if topic
      by_topic(topic)
    else
      none
    end
  end

  scope :by_author, -> (author) do
    ids = Dummy::Blog::AuthorArticleLink.select(:dummy_blog_article_id)
                                        .where(author:)

    where(id: ids)
  end

  scope :by_author_slug, -> (slug) do
    author = Dummy::Blog::Author.find_by(slug:)

    if author
      by_author(author)
    else
      none
    end
  end

  scope :public_filter_by_topics, -> (topics_param) do
    if topics_param.present?
      topic_ids = Dummy::Blog::Topic.where(slug: topics_param).select(:id)
      article_ids = Dummy::Blog::TopicArticleLink.where(dummy_blog_topic_id: topic_ids).select(:dummy_blog_article_id)
      where(id: article_ids)
    else
      all
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
      cover_placement:,
      title:,
      url_for_args: self,
      content: ActionController::Base.helpers.content_tag(:p, perex),
    )
  end

  def folio_ai_context(field_key:, current_form_snapshot:)
    {
      title:,
      perex:,
      meta_title:,
      meta_description:,
      current_form_snapshot: current_form_snapshot.presence,
    }.compact
  end

  def folio_ai_suggestions_eligible?(field_key:, current_form_snapshot:)
    persisted? && [title, perex].any?(&:present?)
  end

  def folio_ai_provider_adapter
    self.class.folio_ai_demo_provider_adapter_class.new
  end

  def self.folio_ai_demo_provider_adapter_class
    DemoAiProviderAdapter
  end

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

  class DemoAiProviderAdapter
    def generate_suggestions(prompt:, field:, suggestion_count:)
      Array.new(suggestion_count) do |index|
        Folio::Ai::Suggestion.new(key: index + 1,
                                  text: suggestion_text(field, index),
                                  meta: { tone_label: tone_label(index) })
      end
    end

    private
      def suggestion_text(field, index)
        text = base_texts(field.key).fetch(index % 3)

        if field.character_limit.present?
          text.truncate(field.character_limit)
        else
          text
        end
      end

      def base_texts(field_key)
        case field_key.to_s
        when "title"
          [
            "Demo AI headline focused on the main editorial hook",
            "Clear demo headline with a stronger reader promise",
            "Short demo headline generated by the Folio AI panel",
          ]
        when "perex"
          [
            "Demo AI perex summarizing the article angle and giving editors a safe suggestion to accept or rewrite.",
            "Alternative demo summary that shows regeneration, copy, accept and ghost undo without a real provider.",
            "Concise AI-generated demo perex for validating the shared Folio suggestion panel.",
          ]
        when "meta_title"
          [
            "Demo SEO title for Folio AI",
            "Folio AI suggestion demo",
            "AI-generated demo meta title",
          ]
        else
          [
            "Demo meta description generated by the Folio AI panel for local verification.",
            "Alternative AI meta description showing the reusable HTML API contract.",
            "Concise demo description for checking copy, accept and undo states.",
          ]
        end
      end

      def tone_label(index)
        %w[Neutral Short Editorial].fetch(index % 3)
      end
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
