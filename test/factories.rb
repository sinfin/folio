# frozen_string_literal: true

def get_current_or_existing_site_or_create_from_factory
  site = begin
    Folio::Current.site&.reload
  rescue ActiveRecord::RecordNotFound
    nil
  end
  site || Folio::Site.last || create(Rails.application.config.folio_site_default_test_factory)
end

def safely_set_roles_for(user, roles, site)
  # to avoid check, if current user can actually assing such roles
  if Folio::Current.respond_to?(:stub)
    Folio::Current.stub(:user, nil) do
      user.set_roles_for(site:, roles:)
    end
  else # usage of factories outside TEST env
    Folio::Current.user = nil
  end
end

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
  end

  if Rails.application.class.name.deconstantize == "Dummy"
    factory :dummy_site, class: "Dummy::Site", parent: :folio_site
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
    site { get_current_or_existing_site_or_create_from_factory }

    trait :unpublished do
      published { false }
      published_at { nil }
    end
  end

  factory :folio_page_cookies, parent: :folio_page, class: "Folio::Page::Cookies"

  factory :folio_file_placement_cover, class: "Folio::FilePlacement::Cover" do
    association :file, factory: :folio_file_image
    association :placement, factory: :folio_page
  end

  factory :folio_file_placement_document, class: "Folio::FilePlacement::Document" do
    association :file, factory: :folio_file_document
    association :placement, factory: :folio_page
  end

  factory :folio_file_placement_image, class: "Folio::FilePlacement::Image" do
    association :file, factory: :folio_file_image
    association :placement, factory: :folio_page
  end

  factory :folio_file_placement_image_or_embed, class: "Folio::FilePlacement::ImageOrEmbed" do
    association :file, factory: :folio_file_image
    association :placement, factory: :folio_page
  end

  factory :folio_file, class: "Folio::File" do
    alt { "alt" }
    author { "author" }
    attribution_source { "attribution_source" }
    description { "description" }
  end


  factory :folio_file_image, parent: :folio_file, class: "Folio::File::Image" do
    file { Folio::Engine.root.join("test/fixtures/folio/test.gif") }
    site { get_current_or_existing_site_or_create_from_factory }
    association :media_source, factory: :folio_media_source

    trait :black do
      file { Folio::Engine.root.join("test/fixtures/folio/test-black.gif") }
    end
  end

  factory :folio_file_document, parent: :folio_file, class: "Folio::File::Document" do
    file { Folio::Engine.root.join("test/fixtures/folio/empty.pdf") }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :folio_file_audio, parent: :folio_file, class: "Folio::File::Audio" do
    file { Folio::Engine.root.join("test/fixtures/folio/blank.mp3") }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :folio_file_video, parent: :folio_file, class: "Folio::File::Video" do
    file { Folio::Engine.root.join("test/fixtures/folio/blank.mp4") }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :folio_private_attachment, class: "Folio::PrivateAttachment" do
    file { Folio::Engine.root.join("test/fixtures/folio/empty.pdf") }
  end

  factory :folio_lead, class: "Folio::Lead" do
    email { "folio@folio.folio" }
    phone { "+420 123456789" }
    note { "Officiis perferendis commodi." }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :folio_media_source, class: "Folio::MediaSource" do
    sequence(:title) { |n| "Media Source #{n}" }
    licence { "CC BY 4.0" }
    copyright_text { "Copyright" }
    max_usage_count { 5 }
    site { get_current_or_existing_site_or_create_from_factory }
  end

  factory :folio_menu, class: "Folio::Menu" do
    locale { :cs }
    sequence(:title) { |i| "Menu #{i}" }
    site { get_current_or_existing_site_or_create_from_factory }
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
    site { get_current_or_existing_site_or_create_from_factory }
    active { true }
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
    auth_site { get_current_or_existing_site_or_create_from_factory }
    preferred_locale { "cs" }

    trait :superadmin do
      superadmin { true }
    end

    trait :manager do
      after(:create) do |user|
        safely_set_roles_for(user, ["manager"], user.auth_site)
        user.reload
      end
    end
  end

  factory :folio_omniauth_authentication, class: "Folio::Omniauth::Authentication" do
    provider { "facebook" }
    sequence(:email) { |i| "email-#{i}@example.com" }
    nickname { "nickname" }
    access_token { "access_token" }
    raw_info { { some: "info" }.to_json }

    association :user, factory: :folio_user
    conflict_user_id { nil }
    conflict_token { "conflict_token" }

    trait :with_untrusted_email do
      email { "user@privaterelay.appleid.com" }
    end
  end

  factory :folio_site_user_link, class: "Folio::SiteUserLink" do
    site { get_current_or_existing_site_or_create_from_factory }
    user { create(:folio_user) }
    transient do
      roles { [] }
    end

    after(:build) do |site_user_link, evaluator|
      if Folio::Current.respond_to?(:stub)
        Folio::Current.stub(:user, nil) do
          site_user_link.roles = evaluator.roles
        end
      else
        Folio::Current.user = nil
      end
    end
  end

  factory :folio_newsletter_subscription, class: "Folio::NewsletterSubscription" do
    sequence(:email) { |i| "email-#{i}@email.email" }
    site { get_current_or_existing_site_or_create_from_factory }
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

  factory :dummy_menu_footer, class: "Dummy::Menu::Footer", parent: :folio_menu

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

  factory :folio_video_subtitle, class: "Folio::VideoSubtitle" do
    association :video, factory: :folio_file_video
    language { "cs" }
    format { "vtt" }
    enabled { false }
    text { "00:00:01.000 --> 00:00:02.000\nSample subtitle text" }
    metadata { {} }

    trait :enabled do
      enabled { true }
    end

    trait :auto_generated do
      after(:create) do |subtitle|
        subtitle.update_transcription_metadata(
          "job_class" => "Folio::ElevenLabs::TranscribeSubtitlesJob",
          "state" => "ready",
          "completed_at" => Time.current.iso8601,
          "attempts" => 1
        )
        subtitle.save!
      end
    end

    trait :processing do
      after(:create) do |subtitle|
        subtitle.update_transcription_metadata(
          "job_class" => "Folio::ElevenLabs::TranscribeSubtitlesJob",
          "state" => "processing",
          "processing_started_at" => Time.current.iso8601,
          "attempts" => 1
        )
        subtitle.save!
      end
    end

    trait :failed do
      after(:create) do |subtitle|
        subtitle.update_transcription_metadata(
          "job_class" => "Folio::ElevenLabs::TranscribeSubtitlesJob",
          "state" => "failed",
          "completed_at" => Time.current.iso8601,
          "error_message" => "Transcription failed",
          "attempts" => 1
        )
        subtitle.save!
      end
    end

    trait :manual_override do
      after(:create) do |subtitle|
        subtitle.update_transcription_metadata(
          "job_class" => "Folio::ElevenLabs::TranscribeSubtitlesJob",
          "state" => "manual_override"
        )
        subtitle.update_manual_edits_metadata
        subtitle.save!
      end
    end

    trait :invalid_content do
      text { "Invalid VTT content without proper format" }
    end
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
        after(:build) { |model| model.site ||= get_current_or_existing_site_or_create_from_factory }
      end
    end
  end
end
