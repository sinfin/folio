# frozen_string_literal: true

require "test_helper"

class Folio::StimulusHelperTest < ActiveSupport::TestCase
  include Folio::StimulusHelper

  class MockPublishableRecord
    attr_accessor :published

    def initialize(published:)
      @published = published
    end

    def published?
      @published
    end
  end

  class MockFrontendController
    attr_accessor :params, :record_for_meta_variables

    def initialize(params: {}, record_for_meta_variables: nil)
      @params = params
      @record_for_meta_variables = record_for_meta_variables
    end

    def is_a?(klass)
      klass == ActionController::Base
    end

    def instance_variable_get(name)
      @record_for_meta_variables if name == :@record_for_meta_variables
    end

    def present?
      true
    end
  end

  class MockConsoleController < Folio::Console::BaseController
    attr_accessor :params, :record_for_meta_variables

    def initialize(params: {}, record_for_meta_variables: nil)
      @params = params
      @record_for_meta_variables = record_for_meta_variables
    end

    def instance_variable_get(name)
      @record_for_meta_variables if name == :@record_for_meta_variables
    end

    def present?
      true
    end
  end

  def setup
    super
    @folio_thumbnails_enabled = nil
  end

  test "stimulus_thumbnail returns nil for non-doader URL" do
    @controller = MockFrontendController.new
    result = stimulus_thumbnail(src: "https://example.com/image.jpg")
    assert_nil result
  end

  test "stimulus_thumbnail returns nil on regular frontend with published record" do
    record = MockPublishableRecord.new(published: true)
    @controller = MockFrontendController.new(
      params: {},
      record_for_meta_variables: record
    )
    @folio_thumbnails_enabled = nil

    result = stimulus_thumbnail(src: "https://doader.com/placeholder.jpg")
    assert_nil result
  end

  test "stimulus_thumbnail returns nil with preview param but published record" do
    record = MockPublishableRecord.new(published: true)
    @controller = MockFrontendController.new(
      params: { Folio::Publishable::PREVIEW_PARAM_NAME => "abc123" },
      record_for_meta_variables: record
    )
    @folio_thumbnails_enabled = nil

    result = stimulus_thumbnail(src: "https://doader.com/placeholder.jpg")
    assert_nil result
  end

  test "stimulus_thumbnail returns controller data in console" do
    @controller = MockConsoleController.new(params: {})
    @folio_thumbnails_enabled = nil

    result = stimulus_thumbnail(src: "https://doader.com/placeholder.jpg")
    assert_not_nil result
    assert_equal "f-thumbnail", result["controller"]
  end

  test "stimulus_thumbnail returns controller data with preview param AND unpublished record" do
    record = MockPublishableRecord.new(published: false)
    @controller = MockFrontendController.new(
      params: { Folio::Publishable::PREVIEW_PARAM_NAME => "abc123" },
      record_for_meta_variables: record
    )
    @folio_thumbnails_enabled = nil

    result = stimulus_thumbnail(src: "https://doader.com/placeholder.jpg")
    assert_not_nil result
    assert_equal "f-thumbnail", result["controller"]
  end

  test "stimulus_thumbnail returns nil with preview param but no record" do
    @controller = MockFrontendController.new(
      params: { Folio::Publishable::PREVIEW_PARAM_NAME => "abc123" },
      record_for_meta_variables: nil
    )
    @folio_thumbnails_enabled = nil

    result = stimulus_thumbnail(src: "https://doader.com/placeholder.jpg")
    assert_nil result
  end

  test "stimulus_thumbnail returns nil with preview param but record without published method" do
    @controller = MockFrontendController.new(
      params: { Folio::Publishable::PREVIEW_PARAM_NAME => "abc123" },
      record_for_meta_variables: Object.new
    )
    @folio_thumbnails_enabled = nil

    result = stimulus_thumbnail(src: "https://doader.com/placeholder.jpg")
    assert_nil result
  end

  # Must be public for respond_to?(:controller) check in helper
  attr_reader :controller
end
