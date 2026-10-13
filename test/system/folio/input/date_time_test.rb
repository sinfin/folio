# frozen_string_literal: true

require "test_helper"

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

  test "a time arrow tapped right after a typed value keeps the picker open and applies" do
    open_picker("Default")
    field("Default").set("8. 10. 2026, 15:30")
    tap(find("#{WIDGET} [data-action='incrementHours']"))

    assert_selector WIDGET
    assert_equal "8. 10. 2026, 16:30", field_value("Default")
  end

  # The day is one that min rejects, so the picker stays open under the cursor.
  test "fast clicks on the time arrows and on a day select no text in the picker" do
    restrict_and_set("Default", min: "2030-06-14T12:00:00", value: "2030-06-15T08:00:00")
    open_picker("Default")

    double_click_action("incrementMinutes")
    assert_selector WIDGET
    assert_empty selected_text

    double_click_action("decrementHours")
    assert_selector WIDGET
    assert_empty selected_text

    find("#{WIDGET} .day[data-action='selectDay'][data-value='2030-06-14']").double_click
    assert_selector WIDGET
    assert_empty selected_text
  end

  # The first click closes the picker, the second lands on the page underneath:
  # it must neither select text there nor click or double-click it.
  test "a double click on a day does not reach the page underneath" do
    open_picker("Default")
    count_page_clicks
    find("#{WIDGET} .day[data-action='selectDay']:not(.old):not(.new):not(.disabled)", match: :first).double_click

    assert_no_selector WIDGET
    assert_not_empty field_value("Default")
    assert_empty selected_text
    assert_equal({ "click" => 0, "dblclick" => 0 }, evaluate_script("window.folioTestPageClicks"))
  end

  test "a double click elsewhere right after a day pick still selects text" do
    open_picker("Default")
    find("#{WIDGET} .day[data-action='selectDay']:not(.old):not(.new):not(.disabled)", match: :first).click
    assert_no_selector WIDGET

    find("h2", text: "Input date time").double_click

    assert_not_empty selected_text
  end

  # Fixed dates in the browser's own time zone: the 14th is selectable (same day
  # as min), but the picked time 08:00 is before min 12:00, so TD rejects it.
  test "a day rejected by min keeps the picker open" do
    restrict_and_set("Default", min: "2030-06-14T12:00:00", value: "2030-06-15T08:00:00")
    open_picker("Default")
    value = field_value("Default")

    find("#{WIDGET} .day[data-action='selectDay'][data-value='2030-06-14']").click

    assert_selector WIDGET
    assert_equal value, field_value("Default")
  end

  # max is the browser's "now": the empty input starts at now, so +1 h is out of range
  test "a disabled arrow leaves nothing behind for the next typed value" do
    restrict_max_to_browser_now("Default")
    open_picker("Default")
    arrow = find("#{WIDGET} [data-action='incrementHours']")
    assert arrow[:class].include?("disabled")
    arrow.click

    field("Default").set("1. 1. 2020, 10:00")
    field("Default").send_keys(:tab)

    assert_no_selector WIDGET
    assert_equal "1. 1. 2020, 10:00", field_value("Default")
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

    def double_click_action(action)
      find("#{WIDGET} [data-action='#{action}']").double_click
    end

    # a touch pointer: Chrome sends pointer events first and the compatibility
    # mouse events (with the blur of the focused input) after pointerup
    def tap(element)
      finger = Selenium::WebDriver::Interactions.pointer(:touch, name: "finger")
      page.driver.browser.action(devices: [finger]).move_to(element.native).pointer_down(:left).pointer_up(:left).perform
    end

    # counts clicks that reach page elements outside the picker widget
    def count_page_clicks
      execute_script(<<~JS)
        window.folioTestPageClicks = { click: 0, dblclick: 0 }
        const count = (e) => {
          if (!e.target.closest || !e.target.closest('.tempus-dominus-widget')) window.folioTestPageClicks[e.type] += 1
        }
        document.addEventListener('click', count)
        document.addEventListener('dblclick', count)
      JS
    end

    def selected_text
      evaluate_script("window.getSelection().toString()")
    end

    def restrict_max_to_browser_now(label)
      execute_script(<<~JS, field(label).native)
        const [input] = arguments
        input.folioInputTempusDominus.updateOptions({ restrictions: { maxDate: new window.tempusDominus.DateTime() } })
      JS
    end

    # local ISO strings without an offset are read in the browser's time zone
    def restrict_and_set(label, min:, value:)
      execute_script(<<~JS, field(label).native, min, value)
        const [input, min, value] = arguments
        const picker = input.folioInputTempusDominus
        picker.updateOptions({ restrictions: { minDate: new window.tempusDominus.DateTime(min) } })
        picker.dates.setValue(new window.tempusDominus.DateTime(value))
      JS
    end
end
