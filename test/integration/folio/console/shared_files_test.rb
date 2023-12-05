# frozen_string_literal: true

require "test_helper"

class Folio::SharedFilesTest < Folio::Console::BaseControllerTest
  attr_reader :admin, :main_site, :site_lvh, :lvh_image, :shared_image

  def setup
    @main_site = create(:folio_site, domain: Rails.application.config.folio_main_site_domain)
    @site_lvh = create(:folio_site, domain: "lvh.me")
    @admin = create(:folio_account)

    @lvh_image = create(:folio_file_image, site: site_lvh)
    @shared_image = create(:folio_file_image, :black, site: main_site)
    assert_not_equal lvh_image.file_name, shared_image.file_name
  end

  test "`config.folio_shared_files_between_sites` is true: files stored under main_site are available at any site, not the other way" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      [main_site, site_lvh].each do |site|
        host_site(site)
        sign_in admin

        get console_api_file_images_url(host: site.domain,
                                        only_path: false,
                                        params: { by_file_name: "test" }) # params are here to disable caching

        assert_response :success, response.body

        assert file_data_in_json(response.body, shared_image).present?,
                "Data #{shared_image.file_name} not found in response for `#{site.domain}`"
        if site == main_site
          assert_nil file_data_in_json(response.body, lvh_image), response.body
        else
          assert file_data_in_json(response.body, lvh_image).present?,
                  "Data #{lvh_image.file_name} not found in response for `#{site.domain}`"
        end
      end
    end
  end

  test "`config.folio_shared_files_between_sites` is true: console resource menu is outside sites block" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
    end
  end

  test "`config.folio_shared_files_between_sites` is true: files are stored always under main_site" do
    # proces of creating file is
    # 1) run before_folio_api_s3_path to get s3_url
    # 2) upload file to s3_url
    # 3) run after_folio_api_s3_path to process file
    # so I will test only 3)
    host_site(site_lvh)
    sign_in admin

    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      # klasses Folio::File::Document, Folio::File::Image, Folio::PrivateAttachment
      klass = Folio::File::Image
      s3_name = "test-#{klass.model_name.singular}.gif"
      test_path = "#{Folio::S3::Client::TEST_PATH}/#{s3_name}"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_difference("#{klass}.count", 1) do
        perform_enqueued_jobs do
          post after_folio_api_s3_path, params: { s3_path: s3_name, type: klass.to_s, existing_id: nil }
          assert_response(:ok)
        end
      end

      file_record = klass.last
      assert_equal main_site, file_record.site
    end
  end

  test "`config.folio_shared_files_between_sites` is false: files are available only at theirs site" do
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      [main_site, site_lvh].each do |site|
        host_site(site)
        sign_in admin

        get console_api_file_images_url(host: site.domain,
                                        only_path: false,
                                        params: { by_file_name: "test" }) # params are here to disable caching

        assert_response :success, response.body

        if site == main_site
          assert file_data_in_json(response.body, shared_image).present?,
               "Data #{shared_image.file_name} not found in response for `#{site.domain}`"
          assert_nil file_data_in_json(response.body, lvh_image), response.body
        else
          assert_nil file_data_in_json(response.body, shared_image), response.body
          assert file_data_in_json(response.body, lvh_image).present?,
                 "Data #{lvh_image.file_name} not found in response for `#{site.domain}`"
        end
      end
    end
  end

  test "`config.folio_shared_files_between_sites` is false: console resource menu is inside sites block" do
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
    end
  end

  test "`config.folio_shared_files_between_sites` is false: files are stored under current_site" do
    host_site(site_lvh)
    sign_in admin

    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      # klasses Folio::File::Document, Folio::File::Image, Folio::PrivateAttachment
      klass = Folio::File::Image
      s3_name = "test-#{klass.model_name.singular}.gif"
      test_path = "#{Folio::S3::Client::TEST_PATH}/#{s3_name}"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_difference("#{klass}.count", 1) do
        perform_enqueued_jobs do
          post after_folio_api_s3_path, params: { s3_path: s3_name, type: klass.to_s, existing_id: nil }
          assert_response(:ok)
        end
      end

      file_record = klass.last
      assert_equal site_lvh, file_record.site
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
