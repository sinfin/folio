# frozen_string_literal: true

FactoryBot.define do
  factory :folio_site, class: "Folio::Site" do
    title { "Folio" }
    sequence(:domain) { |n| "folio-#{n}.com" }
    email { "folio@folio.folio" }
    social_links { { "facebook" => "http://www.facebook.com/folio" } }
    address { "90682 Folio Square\nFolio" }
    phone { "+420 123456789" }
    locale { I18n.default_locale }
    locales { [I18n.default_locale] }
    type { "Folio::Site" }
  end

  factory :sinfin_local_site, parent: :folio_site do
    title { "Sinfin local" }
    domain { "sinfin.localhost" }
    email { "dummy@sinfin.localhost" }
    social_links { { "facebook" => "http://www.facebook.com/sinfin" } }
  end

  factory :folio_page, class: "Folio::Page" do
    locale { :cs }
    if Rails.application.config.folio_using_traco
      I18n.available_locales.each do |locale|
        sequence("title_#{locale}".to_sym) { |n| "Folio page #{n}" }
        sequence("slug_#{locale}".to_sym) { |n| "folio-page-#{n}" }
      end
    else
      sequence(:title) { |n| "Folio page #{n}" }
      sequence(:slug) { |n| "folio-page-#{n}" }
    end
    published { true }
    published_at { 1.day.ago }
    site { Folio::Site.first || create(:folio_site) }

    trait :unpublished do
      published { false }
      published_at { nil }
    end
  end

  factory :folio_page_cookies, parent: :folio_page, class: "Folio::Page::Cookies"

  factory :folio_document_placement, class: "Folio::FilePlacement::Document" do
    association :file, factory: :folio_file_document
    association :placement, factory: :folio_page
  end

  factory :folio_image_placement, class: "Folio::FilePlacement::Image" do
    association :file, factory: :folio_file_image
    association :placement, factory: :folio_page
  end

  factory :folio_cover_placement, class: "Folio::FilePlacement::Cover" do
    association :file, factory: :folio_file_image
    association :placement, factory: :folio_page
  end

  factory :folio_file_image, class: "Folio::File::Image" do
    file { Folio::Engine.root.join("test/fixtures/folio/test.gif") }
    site { Folio::Site.first || create(:folio_site) }

    trait :black do
      file { Folio::Engine.root.join("test/fixtures/folio/test-black.gif") }
    end
  end

  factory :folio_file_document, class: "Folio::File::Document" do
    file { Folio::Engine.root.join("test/fixtures/folio/empty.pdf") }
    site { Folio::Site.first || create(:folio_site) }
  end

  factory :folio_file_audio, class: "Folio::File::Audio" do
    file { Folio::Engine.root.join("test/fixtures/folio/blank.mp3") }
    site { Folio::Site.first || create(:folio_site) }
  end

  factory :folio_file_video, class: "Folio::File::Video" do
    file { Folio::Engine.root.join("test/fixtures/folio/blank.mp4") }
    site { Folio::Site.first || create(:folio_site) }
  end

  factory :folio_private_attachment, class: "Folio::PrivateAttachment" do
    file { Folio::Engine.root.join("test/fixtures/folio/empty.pdf") }
  end

  factory :folio_lead, class: "Folio::Lead" do
    email { "folio@folio.folio" }
    phone { "+420 123456789" }
    note { "Officiis perferendis commodi." }
    site { Folio::Site.first || create(:folio_site) }
  end

  factory :folio_account, class: "Folio::Account" do
    sequence(:email) { |i| "test-#{i}@test.com" }
    password { "Complex@Password.123" }
    roles { %w[superuser] }
    first_name { "Test" }
    last_name { "Dummy" }
  end

  factory :folio_admin_account, parent: :folio_account

  factory :folio_menu, class: "Folio::Menu" do
    locale { :cs }
    sequence(:title) { |i| "Menu #{i}" }
    site { Folio::Site.first || create(:folio_site) }
  end

  factory :folio_menu_page, class: "Folio::Menu::Page", parent: :folio_menu

  factory :folio_menu_item, class: "Folio::MenuItem" do
    association :menu, factory: :folio_menu
    association :target, factory: :folio_page
    title { "MenuItem" }
    position { 0 }
  end

  factory :folio_session_attachment_image,
          class: "Dummy::SessionAttachment::Image" do
    file { Folio::Engine.root.join("test/fixtures/folio/test.gif") }
    web_session_id { "web_session_id" }
  end

  factory :folio_session_attachment_document,
          parent: :folio_session_attachment_image,
          class: "Dummy::SessionAttachment::Document"

  factory :folio_email_template,
          class: "Folio::EmailTemplate" do
    mailer { "mailer" }
    action { "action" }
    title { "title" }
    subject_cs { "subject_cs" }
    subject_en { "subject_en" }
    body_html_cs { "body_html_cs" }
    body_html_en { "body_html_en" }
    body_text_cs { "body_text_cs" }
    body_text_en { "body_text_en" }
    optional_keywords { [] }
    required_keywords { [] }
    site { Folio::Site.first || create(:folio_site) }
  end

  factory :folio_user, class: "Folio::User" do
    sequence(:email) { |i| "email-#{i}@email.email" }
    password { "Complex@Password.123" }
    confirmed_at { Time.now }
    first_name { "first_name" }
    last_name { "last_name" }
    phone { "+420604123123" }
    superadmin { false }
    association(:primary_address, factory: :folio_address_primary)
  end

  factory :folio_site_user_link, class: "Folio::SiteUserLink" do
    site { Folio::Site.first || create(:folio_site) }
    user { create(:folio_user) }
    roles { [] }
  end

  factory :folio_newsletter_subscription, class: "Folio::NewsletterSubscription" do
    sequence(:email) { |i| "email-#{i}@email.email" }
    site { Folio::Site.first || create(:folio_site) }
  end

  factory :folio_console_note, class: "Folio::ConsoleNote" do
    content { "content" }
    association(:target, factory: :folio_page)
  end

  factory :folio_address_primary, class: "Folio::Address::Primary" do
    address_line_1 { "address_line_1" }
    address_line_2 { "address_line_2" }
    city { "city" }
    zip { "zip" }
    country_code { "cc" }
  end

  factory :dummy_menu, class: "Dummy::Menu::Navigation", parent: :folio_menu

  factory :dummy_blog_article, class: "Dummy::Blog::Article" do
    sequence(:title) { |i| "Article title #{i + 1}" }
    perex { "perex" }
    published { true }
  end

  factory :dummy_blog_topic, class: "Dummy::Blog::Topic" do
    sequence(:title) { |i| "Topic title #{i + 1}" }
    published { true }
  end
end

if Rails.application.config.folio_site_default_test_factory
  FactoryBot.modify do
    %i[
      folio_email_template
      folio_lead
      folio_menu
      folio_newsletter_subscription
      folio_page
    ].each do |key|
      factory key do
        after(:build) { |model| model.site ||= Folio.main_site || create(Rails.application.config.folio_site_default_test_factory) }
      end
    end
  end
end
