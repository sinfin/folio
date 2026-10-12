# frozen_string_literal: true

require "test_helper"

# Selenium talks to chromedriver over local HTTP (WebDriver protocol, on
# whatever port the service got) and Capybara pings its own server. Let VCR
# pass exactly those requests through; blocking them, including the shutdown
# call, leaves chromedriver processes behind.
WEBDRIVER_LOCAL_PATHS = %r{\A/(session|status|shutdown|__identify__)\b}

VCR.configure do |config|
  config.ignore_request do |request|
    uri = URI(request.uri)
    %w[127.0.0.1 localhost ::1].include?(uri.host) && uri.path.match?(WEBDRIVER_LOCAL_PATHS)
  end
end

# Real-browser behaviour of the `f-input-date-time` picker on the console UI
# page: which clicks keep the Tempus Dominus widget open and which close it.
class Folio::Input::DateTimeTest < ActionDispatch::SystemTestCase
  include Warden::Test::Helpers

  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1000]

  WIDGET = ".tempus-dominus-widget.show"

  def setup
    super
    # console layouts skip their JS and CSS in tests unless asked to render them
    @test_with_assets = ENV["TEST_WITH_ASSETS"]
    ENV["TEST_WITH_ASSETS"] = "1"

    @site = create(:dummy_site, domain: "dummy.localhost")
    @superadmin = create(:folio_user, :superadmin)
    Capybara.app_host = "http://dummy.localhost:#{Capybara.current_session.server.port}"
    login_as(@superadmin, scope: :user)
    visit "/console/ui/input_date_time"
  end

  def teardown
    Warden.test_reset!
    Capybara.app_host = nil
    ENV["TEST_WITH_ASSETS"] = @test_with_assets
    super
  end

  test "time arrows keep the picker open on an empty input" do
    open_picker("Default")
    click_action("incrementHours")
    click_action("incrementHours")

    assert_selector WIDGET
    assert_match(/\A\d{1,2}\. \d{1,2}\. \d{4}, \d{1,2}:\d{2}\z/, field_value("Default"))
  end

  test "picking a day closes the picker" do
    open_picker("Default")
    find("#{WIDGET} .day[data-action='selectDay']:not(.old):not(.new):not(.disabled)", match: :first).click

    assert_no_selector WIDGET
    assert_not_empty field_value("Default")
  end

  test "picking the already selected day after a time arrow closes the picker" do
    open_picker("Default")
    click_action("incrementHours")
    value = field_value("Default")

    find("#{WIDGET} .day.active[data-action='selectDay']").click

    assert_no_selector WIDGET
    assert_equal value, field_value("Default")
  end

  test "clear closes the picker and empties the input" do
    open_picker("Default")
    click_action("incrementHours")
    click_action("clear")

    assert_no_selector WIDGET
    assert_equal "", field_value("Default")
  end

  test "typing a value and leaving the input closes the picker" do
    open_picker("Default")
    field("Default").set("8. 10. 2026, 15:30")
    field("Default").send_keys(:tab)

    assert_no_selector WIDGET
    assert_equal "8. 10. 2026, 15:30", field_value("Default")
  end

  test "a time arrow right after a typed value keeps the picker open and applies" do
    open_picker("Default")
    field("Default").set("8. 10. 2026, 15:30")
    click_action("incrementHours")

    assert_selector WIDGET
    assert_equal "8. 10. 2026, 16:30", field_value("Default")
  end

  test "a day rejected by min keeps the picker open" do
    tomorrow = 1.day.from_now.beginning_of_day + 30.minutes
    set_value("Min", tomorrow)
    open_picker("Min")

    find("#{WIDGET} .day.today[data-action='selectDay']").click

    assert_selector WIDGET
    assert_equal I18n.l(tomorrow, format: "%-d. %-m. %Y, %-H:%M"), field_value("Min")
  end

  test "a disabled arrow leaves nothing behind for the next typed value" do
    open_picker("Max")
    arrow = find("#{WIDGET} [data-action='incrementHours']")
    assert arrow[:class].include?("disabled")
    arrow.click

    field("Max").set("1. 1. 2020, 10:00")
    field("Max").send_keys(:tab)

    assert_no_selector WIDGET
    assert_equal "1. 1. 2020, 10:00", field_value("Max")
  end

  private
    # SimpleForm labels point at a Rails datetime-select id ("default_4i"), so
    # the input is found by its form group class instead of the label
    def field(name)
      date_time_form.find(".form-group._#{name.downcase} input.f-input--date-time")
    end

    # the page renders a "Date time" form and a date-only "Date" form below it
    def date_time_form
      find(:xpath, "//h3[normalize-space()='Date time']/following-sibling::form[1]")
    end

    def field_value(label)
      field(label).value
    end

    def open_picker(label)
      field(label).click
      assert_selector WIDGET
    end

    def click_action(action)
      find("#{WIDGET} [data-action='#{action}']").click
    end

    def set_value(label, time)
      execute_script(<<~JS, field(label).native, time.iso8601)
        const [input, iso] = arguments
        input.folioInputTempusDominus.dates.setValue(new window.tempusDominus.DateTime(iso))
      JS
    end
end
