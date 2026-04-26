# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["TEST_WITH_ASSETS"] ||= "1"

require "fileutils"

FOLIO_ROOT = File.expand_path("../..", __dir__)
TIMESTAMP = ENV.fetch("AI_SCREENSHOT_TIMESTAMP", Time.now.strftime("%Y%m%d-%H%M%S"))
SCREENSHOT_BASE = File.expand_path(ENV.fetch("AI_SCREENSHOT_ROOT", "tmp/ai-screenshots-#{TIMESTAMP}"), FOLIO_ROOT)
SCREENSHOT_ROOT = File.join(SCREENSHOT_BASE, "folio-dummy")
ECONOMIA_ROOT = File.expand_path(ENV.fetch("ECONOMIA_ROOT", "../economia"), FOLIO_ROOT)

REDACTOR_SOURCES = [
  File.join(ECONOMIA_ROOT, "vendor/assets/redactor"),
  File.join(FOLIO_ROOT, "lib/templates/vendor/assets/redactor"),
].freeze
REDACTOR_TARGET = File.join(FOLIO_ROOT, "test/dummy/vendor/assets/redactor")
CREATED_REDACTOR_ASSETS = []

def install_screenshot_redactor_asset(name, fallback)
  path = File.join(REDACTOR_TARGET, name)
  return if File.exist?(path)

  source = REDACTOR_SOURCES.lazy
                           .map { |dir| File.join(dir, name) }
                           .find { |candidate| File.file?(candidate) }

  FileUtils.mkdir_p(File.dirname(path))
  if source
    FileUtils.cp(source, path)
  else
    File.write(path, fallback.sub(/\n*\z/, "\n"))
  end
  CREATED_REDACTOR_ASSETS << path
end

install_screenshot_redactor_asset("redactor.js", <<~JS)
  window.Redactor = window.Redactor || {};
  window.$R = window.$R || function () {
    return {
      app: { stop: function () {} },
      source: {
        getCode: function () { return ""; },
        setCode: function () {}
      }
    };
  };
JS
install_screenshot_redactor_asset("redactor.css", ".redactor-box {}\n")

at_exit do
  CREATED_REDACTOR_ASSETS.each do |path|
    File.delete(path) if File.file?(path)
  rescue Errno::ENOENT
    nil
  end
end

$LOAD_PATH.unshift(File.join(FOLIO_ROOT, "test"))

require File.join(FOLIO_ROOT, "test/test_helper")
require "capybara/minitest"
require "capybara/rails"
require "selenium-webdriver"

class FolioAiScreenshotCapture
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include FactoryBot::Syntax::Methods
  include Minitest::Assertions

  attr_accessor :assertions

  def self.call
    new.call
  end

  def initialize
    self.assertions = 0
    @created_records = []
  end

  def call
    setup_capybara
    setup_data
    sign_in
    capture_article_states
    capture_site_settings
    write_readme
    puts "AI screenshots saved to #{SCREENSHOT_BASE}"
  ensure
    cleanup_data
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  private
    def setup_capybara
      FileUtils.mkdir_p(SCREENSHOT_ROOT)

      VCR.configure { |config| config.ignore_localhost = true }
      Capybara.server = :puma, { Silent: true }
      Capybara.server_host = "127.0.0.1"
      Capybara.default_max_wait_time = 10
      Capybara.register_driver(:folio_ai_chrome) do |app|
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--headless=new")
        options.add_argument("--window-size=1440,1400")
        options.add_argument("--disable-gpu")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")

        Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
      end

      Capybara.current_driver = :folio_ai_chrome
    end

    def setup_data
      register_ai_integration

      Rails.application.config.folio_ai_enabled = true
      @site = Dummy::Site.find_or_initialize_by(domain: "127.0.0.1")
      @site_was_new = @site.new_record?
      @site_original_attributes = @site.attributes.slice("title",
                                                          "email",
                                                          "system_email",
                                                          "email_from",
                                                          "locale",
                                                          "locales",
                                                          "ai_settings")
      @site.assign_attributes(title: "Folio AI Screenshots",
                              email: "folio-ai-screenshots@example.test",
                              system_email: "folio-ai-screenshots@example.test",
                              email_from: "folio-ai-screenshots@example.test",
                              locale: "cs",
                              locales: ["cs"],
                              ai_settings: enabled_ai_settings)
      @site.save!

      Folio::Current.reset
      Folio::Current.site = @site

      @email = "folio-ai-screenshots@example.test"
      @password = "Complex@Password.123"
      @user = Folio::User.find_or_initialize_by(email: @email)
      @user_was_new = @user.new_record?
      @user.assign_attributes(password: @password,
                              password_confirmation: @password,
                              confirmed_at: Time.current,
                              first_name: "AI",
                              last_name: "Reviewer",
                              superadmin: true,
                              auth_site: @site,
                              preferred_locale: "cs")
      @user.save!

      @article = Dummy::Blog::Article.create!(site: @site,
                                              title: "AI prompty ve Folio CMS",
                                              perex: "Krátký perex článku pro ověření AI návrhů.",
                                              locale: "cs",
                                              published: true,
                                              published_at: Time.current,
                                              meta_title: "AI prompty",
                                              meta_description: "Popis článku pro AI panel.")
      @created_records << @article
    end

    def register_ai_integration
      Folio::Ai.reset_registry!
      Folio::Ai.register_integration(:dummy_blog_articles,
                                     label: "Dummy blog articles",
                                     fields: [
                                       Folio::Ai::Field.new(key: :title,
                                                            label: "Titulek",
                                                            auto_attach: true,
                                                            input_types: %i[string],
                                                            character_limit: 120),
                                       Folio::Ai::Field.new(key: :perex,
                                                            label: "Perex",
                                                            auto_attach: true,
                                                            input_types: %i[text],
                                                            character_limit: 400),
                                       Folio::Ai::Field.new(key: :meta_title,
                                                            label: "Meta titulek",
                                                            auto_attach: true,
                                                            input_types: %i[string],
                                                            character_limit: 120),
                                       Folio::Ai::Field.new(key: :meta_description,
                                                            label: "Meta description",
                                                            auto_attach: true,
                                                            input_types: %i[text],
                                                            character_limit: 400),
                                     ])
    end

    def enabled_ai_settings
      {
        enabled: true,
        default_provider: "openai",
        default_model: "gpt-5.5",
        integrations: {
          dummy_blog_articles: {
            fields: %i[title perex meta_title meta_description].index_with do |field|
              {
                enabled: true,
                prompt: "Vygeneruj návrh pro pole #{field}.",
              }
            end,
          },
        },
      }
    end

    def sign_in
      visit "/console"
      login_form = all("form", visible: true).find { |form| form.has_button?("Přihlásit se") }

      within(login_form) do
        find("[data-test-id='sign-in-form-email-input']").set(@email)
        find("[data-test-id='sign-in-form-password-input']").set(@password)
        find("[data-test-id='sign-in-form-submit-button']").click
      end
      assert_current_path(/\/console/)
    end

    def capture_article_states
      visit "/console/dummy/blog/articles/#{@article.id}/edit"
      assert_selector(".f-c-ai-text-suggestions__button", minimum: 1)

      save("01-article-default")

      install_pending_ai_api
      first(".f-c-ai-text-suggestions__button").click
      assert_selector(".f-c-ai-text-suggestions__suggestion--loading", count: 3, visible: :all)
      save("02-panel-loading")

      resolve_ai_success
      assert_selector(".f-c-ai-text-suggestions__suggestion", count: 3, visible: :all)
      save("03-panel-variants")

      first(".f-c-ai-text-suggestions__suggestion").click
      assert_selector(".f-c-ai-text-suggestions__suggestion--selected", count: 1)
      assert_selector(".f-c-ai-text-suggestions__undo", visible: true)
      save("04-variant-accepted")

      first(".f-c-ai-text-suggestions__undo").click
      assert_no_selector(".f-c-ai-text-suggestions__suggestion--selected")
      save("05-ghost-undo")

      first(".f-c-ai-text-suggestions__close").click
      assert_no_selector(".f-c-ai-text-suggestions__panel", visible: true)

      install_pending_ai_api
      first(".f-c-ai-text-suggestions__button").click
      resolve_ai_error
      assert_selector(".f-c-ai-text-suggestions__status", text: /tělo článku|obsah/)
      save("06-panel-error-missing-context")
    end

    def capture_site_settings
      visit "/console/site/edit?tab=ai_prompts"
      assert_selector(".f-c-ai-site-settings")
      save("07-site-settings-ai-prompts")
    end

    def install_pending_ai_api
      execute_script(<<~JS)
        window.Folio = window.Folio || {};
        window.Folio.Api = window.Folio.Api || {};
        window.__folioAiPending = {};
        window.__folioOriginalApiPost = window.__folioOriginalApiPost || window.Folio.Api.apiPost;
        window.Folio.Api.apiPost = function () {
          return new Promise(function (resolve, reject) {
            window.__folioAiPending.resolve = resolve;
            window.__folioAiPending.reject = reject;
          });
        };
      JS
    end

    def resolve_ai_success
      execute_script(<<~JS)
        window.__folioAiPending.resolve({
          data: {
            user_instructions: "",
            suggestions: [
              {
                key: "1",
                text: "Bezpečná správa AI promptů zrychlí práci editorů",
                char_count: 54,
                meta: { tone_label: "Neutrální" }
              },
              {
                key: "2",
                text: "AI návrhy ve Folio CMS pomáhají s texty bez ztráty kontroly",
                char_count: 65,
                meta: { tone_label: "Editorský" }
              },
              {
                key: "3",
                text: "Prompty pro AI asistenci jsou řízené podle webu a pole",
                char_count: 57,
                meta: { tone_label: "Krátký" }
              }
            ]
          }
        });
      JS
    end

    def resolve_ai_error
      execute_script(<<~JS)
        window.__folioAiPending.resolve({
          error_code: "host_ineligible",
          message: "Napište nejdříve tělo článku, aby mohl AI asistent generovat relevantní obsah."
        });
      JS
    end

    def save(name)
      path = File.join(SCREENSHOT_ROOT, "#{name}.png")
      page.current_window.resize_to(1440, 1400)
      page.save_screenshot(path)
      puts path
    end

    def write_readme
      FileUtils.mkdir_p(SCREENSHOT_BASE)
      File.write(File.join(SCREENSHOT_BASE, "README.md"), root_readme, mode: "w") unless File.exist?(File.join(SCREENSHOT_BASE, "README.md"))
      File.write(File.join(SCREENSHOT_ROOT, "README.md"), <<~MARKDOWN.sub(/\n*\z/, "\n"))
        # Folio dummy AI screenshots

        Generated by `scripts/development/capture_ai_screenshots.rb`.

        Timestamp: #{TIMESTAMP}

        The browser request to `window.Folio.Api.apiPost` is stubbed, so provider
        API keys are not needed for this visual smoke capture.
      MARKDOWN
    end

    def root_readme
      <<~MARKDOWN.sub(/\n*\z/, "\n")
        # AI screenshots

        Timestamp: #{TIMESTAMP}

        This folder is a local visual QA artifact. It can contain screenshots
        from Folio dummy app, host applications, or both when scripts are run
        with the same `AI_SCREENSHOT_ROOT`.
      MARKDOWN
    end

    def cleanup_data
      Array(@created_records).reverse_each do |record|
        record.destroy if record&.persisted?
      rescue ActiveRecord::ActiveRecordError
        nil
      end

      cleanup_user
      cleanup_site
      Folio::Current.reset
    end

    def cleanup_user
      return unless @user&.persisted?

      @user.destroy if @user_was_new
    rescue ActiveRecord::ActiveRecordError
      nil
    end

    def cleanup_site
      return unless @site&.persisted?

      if @site_was_new
        @site.destroy
      elsif @site_original_attributes
        @site.update(@site_original_attributes)
      end
    rescue ActiveRecord::ActiveRecordError
      nil
    end
end

FolioAiScreenshotCapture.call
