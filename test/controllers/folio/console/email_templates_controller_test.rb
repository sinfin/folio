# frozen_string_literal: true

require "test_helper"

class Folio::Console::EmailTemplatesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::EmailTemplate])
    assert_response :success
    create(:folio_email_template)
    get url_for([:console, Folio::EmailTemplate])
    assert_response :success
  end

  test "edit" do
    model = create(:folio_email_template)
    get url_for([:edit, :console, model])
    assert_response :success
  end

  test "update" do
    model = create(:folio_email_template)
    assert_not_equal("foo", model.title)
    put url_for([:console, model]), params: {
      email_template: {
        title: "foo",
      },
    }
    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("foo", model.reload.title)
  end

  test "folio_using_traco_aware_param_names" do
    get url_for([:console, Folio::EmailTemplate])
    assert_response(:ok)

    Rails.application.config.stub(:folio_using_traco, true) do
      result = controller.send(:folio_using_traco_aware_param_names, :subject, :body_html)
      assert_equal(%i[subject_cs subject_en body_html_cs body_html_en].sort, result.sort)

      result = controller.send(:traco_aware_param_names, :subject, :body_html)
      assert_equal(%i[subject_cs subject_en body_html_cs body_html_en].sort, result.sort)
    end

    Rails.application.config.stub(:folio_using_traco, false) do
      result = controller.send(:folio_using_traco_aware_param_names, :subject, :body_html)
      assert_equal(%i[subject body_html].sort, result.sort)

      result = controller.send(:traco_aware_param_names, :subject, :body_html)
      assert_equal(%i[subject_cs subject_en body_html_cs body_html_en].sort, result.sort)
    end
  end
end
