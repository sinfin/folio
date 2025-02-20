# frozen_string_literal: true

require "test_helper"

class Folio::ConsoleCellTest < ActionView::TestCase
  include SimpleForm::ActionViewExtensions::FormHelper

  def setup
    @cell = Folio::ConsoleCell.new(nil)
    @controller = ActionController::Base.new
    @cell.instance_variable_set(:@controller, @controller)
  end

  test "that preview token is presented even if model object is published" do
    cell_mock = Minitest::Mock.new
    cell_mock.expect(:try, "any_token", [:preview_token])
    cell_mock.expect(:published?, true)

    @cell.stub :url_for, ->(args) { _model, params = *args; params } do
      result = @cell.preview_url_for(cell_mock)
      assert_equal({ preview: "any_token" }, result)
    end
  end
end
