# frozen_string_literal: true

class CreateBlog < ActiveRecord::Migration[6.0]
  def change
    create_table :dummy_blog_articles do |t|
      t.string :title
      t.string :slug
      t.text :perex

      t.string :locale, default: I18n.default_locale

      t.string :preview_token

      t.string :meta_title
      t.text :meta_description

      t.boolean :featured
      t.boolean :published
      t.datetime :published_at

      t.timestamps
    end

    add_index :dummy_blog_articles, :slug
    add_index :dummy_blog_articles, :locale
    add_index :dummy_blog_articles, :featured
    add_index :dummy_blog_articles, :published
    add_index :dummy_blog_articles, :published_at

    create_table :dummy_blog_topics do |t|
      t.string :title
      t.string :slug
      t.text :perex

      t.string :locale, default: I18n.default_locale

      t.boolean :published
      t.boolean :featured

      t.integer :articles_count, default: 0

      t.integer :position

      t.string :preview_token

      t.string :meta_title
      t.text :meta_description

      t.timestamps
    end

    add_index :dummy_blog_topics, :slug
    add_index :dummy_blog_topics, :locale
    add_index :dummy_blog_topics, :featured
    add_index :dummy_blog_topics, :published
    add_index :dummy_blog_topics, :position

    create_table :dummy_blog_topic_article_links do |t|
      t.belongs_to :dummy_blog_topic, index: { name: :dummy_blog_topic_article_links_t_id }
      t.belongs_to :dummy_blog_article, index: { name: :dummy_blog_topic_article_links_a_id }

      t.integer :position

      t.timestamps
    end
  end
end
