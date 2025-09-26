# frozen_string_literal: true

require "test_helper"

class Folio::Console::FileControllerBaseTest < Folio::Console::BaseControllerTest
  [
    Folio::File::Document,
    Folio::File::Image,
    Folio::File::Video,
    Folio::File::Audio,
  ].each do |klass|
    test "#{klass} - show" do
      file = create(klass.model_name.singular)
      get url_for([:console, file])
      assert_response :success
      assert_select "turbo-frame[id=#{Folio::Console::Files::ShowComponent::TURBO_FRAME_ID}]"
    end

    test "#{klass} - index" do
      get url_for([:console, klass])
      assert_response :success
      assert_select "turbo-frame[id=#{klass.console_turbo_frame_id}]"
    end

    test "#{klass} - index_for_modal" do
      get url_for([:console, klass, action: :index_for_modal])
      assert_response :success
      assert_select "turbo-frame[id=#{klass.console_turbo_frame_id(modal: true)}]"

      @superadmin.destroy!

      sign_in create(:folio_user, :manager)
      get url_for([:console, klass, action: :index_for_modal])
      assert_response :success
      assert_select "turbo-frame[id=#{klass.console_turbo_frame_id(modal: true)}]"
    end

    test "#{klass} - index_for_picker" do
      get url_for([:console, klass, action: :index_for_picker])
      assert_response :success
      assert_select "turbo-frame[id=#{klass.console_turbo_frame_id(picker: true)}]"

      @superadmin.destroy!

      sign_in create(:folio_user, :manager)
      get url_for([:console, klass, action: :index_for_picker])
      assert_response :success
      assert_select "turbo-frame[id=#{klass.console_turbo_frame_id(picker: true)}]"
    end
  end
end
