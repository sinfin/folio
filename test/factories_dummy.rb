# frozen_string_literal: true

FactoryBot.define do
  factory :dummy_site, class: "Dummy::Site", parent: :folio_site

  factory :folio_session_attachment_image,
          class: "Dummy::SessionAttachment::Image" do
    file { Folio::Engine.root.join("test/fixtures/folio/test.gif") }
    web_session_id { "web_session_id" }
  end

  factory :folio_session_attachment_document,
          parent: :folio_session_attachment_image,
          class: "Dummy::SessionAttachment::Document"

  factory :dummy_blog_article, class: "Dummy::Blog::Article" do
    sequence(:title) { |i| "Article title #{i + 1}" }
    perex { "perex" }
    published { true }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :dummy_blog_topic, class: "Dummy::Blog::Topic" do
    sequence(:title) { |i| "Topic title #{i + 1}" }
    published { true }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :dummy_blog_author, class: "Dummy::Blog::Author" do
    first_name { "Firstname" }
    sequence(:last_name) { |i| "Lastname #{i + 1}" }
    published { true }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :dummy_folio_attribute_type, class: "Dummy::AttributeType::Page" do
    sequence(:title) { |i| "Title #{i + 1}" }
    data_type { "string" }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :dummy_menu, class: "Dummy::Menu::Navigation", parent: :folio_menu

  factory :dummy_menu_footer, class: "Dummy::Menu::Footer", parent: :folio_menu
end
