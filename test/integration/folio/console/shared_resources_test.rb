# frozen_string_literal: true

require "test_helper"

class Folio::SharedResourcesTest < Folio::Console::BaseControllerTest
  # resources => file models (images, documents) + Folio::ContentTemplate
  attr_reader :admin, :main_site, :site_lvh, :lvh_image, :shared_image

  def setup
    @main_site = create(:folio_site, domain: Rails.application.config.folio_main_site_domain)
    @site_lvh = create(:folio_site, domain: "lvh.me")
    @admin = create(:folio_account)

    @lvh_image = create(:folio_file_image, site: site_lvh)
    @shared_image = create(:folio_file_image, :black, site: main_site)
    assert_not_equal lvh_image.file_name, shared_image.file_name
  end

  test "resources stored under main_site are available at any site" do
    [main_site, site_lvh].each do |site|
      host_site(site)
      sign_in admin

      get console_api_file_images_url(host: site.domain,
                                      only_path: false,
                                      params: { by_file_name: "test" } ) # params are here to disable caching

      assert_response :success, response.body
      assert file_data_in_json(response.body, shared_image).present?, "Data #{shared_image.file_name} not found in response for `#{site.domain}`"
    end
  end

  test "resources stored under NON main_site are available only at that site" do
    host_site(main_site)
    sign_in admin

    get console_api_file_images_url(host: main_site.domain,
                                    only_path: false,
                                    params: { by_file_name: "test" } )

    assert_response :success, response.body
    assert_nil file_data_in_json(response.body, lvh_image), response.body

    host_site(site_lvh)
    sign_in admin

    get console_api_file_images_url(host: site_lvh.domain,
                                    only_path: false,
                                    params: { by_file_name: "test" } )

    assert_response :success, response.body
    assert file_data_in_json(response.body, lvh_image).present?
  end

  test "`config.folio_shared_resources_between_sites` is true : console resource menu is outside sites block" do
    Rails.application.config.stub(:folio_shared_resources_between_sites, true) do
    end
  end

  test "`config.folio_shared_resources_between_sites` is true : resources are stored always under main_site" do
    Rails.application.config.stub(:folio_shared_resources_between_sites, true) do
    end
  end

  test "`config.folio_shared_resources_between_sites` is false : console resource menu is inside sites block" do
    Rails.application.config.stub(:folio_shared_resources_between_sites, false) do
    end
  end

  test "`config.folio_shared_resources_between_sites` is false : resources are stored under current_site" do
    Rails.application.config.stub(:folio_shared_resources_between_sites, false) do
    end
  end


  # test "index" do
  #   get url_for([:console, Folio::EmailTemplate])
  #   assert_response :success
  #   create(:folio_email_template)
  #   get url_for([:console, Folio::EmailTemplate])
  #   assert_response :success
  # end

  # test "edit" do
  #   model = create(:folio_email_template)
  #   get url_for([:edit, :console, model])
  #   assert_response :success
  # end

  # test "update" do
  #   model = create(:folio_email_template)
  #   assert_not_equal("foo", model.title)
  #   put url_for([:console, model]), params: {
  #     email_template: {
  #       title: "foo",
  #     },
  #   }
  #   assert_redirected_to url_for([:edit, :console, model])
  #   assert_equal("foo", model.reload.title)
  # end

  def file_data_in_json(json_body, file)
    json_data = JSON.parse(response.body)["data"]
    json_data.detect { |f_data| f_data["attributes"]["file_name"] == file.file_name }
  end
end
