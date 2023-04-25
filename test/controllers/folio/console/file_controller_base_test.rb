# frozen_string_literal: true

require "test_helper"

class Folio::Console::FileControllerBaseTest < Folio::Console::BaseControllerTest
  [
    Folio::File::Document,
    Folio::File::Image,
    Folio::File::Video,
    Folio::File::Audio,
  ].each do |klass|
    test "#{klass} - index" do
      get url_for([:console, klass])
      assert_response :success
    end

    test "#{klass} - show" do
      file = create(klass.model_name.singular)
      get url_for([:console, file])
      assert_response :success
    end
  end
end
