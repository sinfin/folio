# frozen_string_literal: true

class Dummy::Blog::Topics::FilterListComponent < ApplicationComponent
  MAX_ITEMS_UNCOLLAPSED_MOBILE = 6
  MAX_ITEMS_UNCOLLAPSED_DESKTOP = 20

  def initialize(topics:, url_base:)
    @topics = topics
    @url_base = url_base
  end

  def render?
    @topics.present?
  end

  def ui_topics
    has_active = false

    ary = [{
      label: t(".all"),
      href: url_for(@url_base),
      active: true,
      close: false,
    }]

    @topics.each do |topic|
      slug = topic.slug
      active = params[Dummy::Blog::TOPICS_PARAM].present? && params[Dummy::Blog::TOPICS_PARAM].include?(slug)
      has_active ||= active

      h = if active
        { Dummy::Blog::TOPICS_PARAM => params[Dummy::Blog::TOPICS_PARAM].without(slug) }
      else
        { Dummy::Blog::TOPICS_PARAM => (params[Dummy::Blog::TOPICS_PARAM] || []) + [slug] }
      end.compact

      ary << {
        label: topic.to_label,
        href: url_for([@url_base, h]),
        active:,
      }
    end

    if has_active
      ary[0][:active] = false
    end

    ary
  end
end
