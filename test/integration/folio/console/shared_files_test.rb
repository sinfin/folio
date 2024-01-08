# frozen_string_literal: true

require "test_helper"

class Folio::SharedFilesTest < Folio::Console::BaseControllerTest
  attr_reader :main_site, :site_lvh, :lvh_image, :shared_image

  def setup
    # not calling `super` for reason
    @main_site = create(:folio_site, domain: "sinfin.localhost")
    @site_lvh = create(:folio_site, domain: "lvh.me", locale: "en")
    Folio.instance_variable_set(:@main_site, nil) # to clear the cached version from other tests
    @superadmin = create(:folio_user, :superadmin)

    @lvh_image = create(:folio_file_image, site: site_lvh)
    @shared_image = create(:folio_file_image, :black, site: main_site)
    assert_not_equal lvh_image.file_name, shared_image.file_name
  end

  test "`config.folio_shared_files_between_sites` is true: files stored under main_site are available at any site, not the other way" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      [main_site, site_lvh].each do |site|
        host_site(site)
        sign_in superadmin

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

  test "`config.folio_shared_files_between_sites` is true: console files menu is outside the sites block" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      [main_site, site_lvh].each do |site|
        host_site(site)
        sign_in superadmin

        # it is redirected to pages: get console_root_url(host: main_site.domain, only_path: false)
        get console_pages_url(host: site.domain, only_path: false)

        assert_response :success, response.body

        top_group = Nokogiri::HTML(response.body).css(".f-c-layout-sidebar__group").first # always expanded
        site_group = Nokogiri::HTML(response.body).css(".f-c-layout-sidebar__group--expanded").first

        assert top_group.css(".f-c-layout-sidebar__li:contains(\"Obrázky\")").present?
        assert site_group.css(".f-c-layout-sidebar__li:contains(\"Obrázky\")").blank?
        assert site_group.css(".f-c-layout-sidebar__li:contains(\"Images\")").blank?

        assert top_group.css(".f-c-layout-sidebar__part-title").blank?
        assert_equal site.domain, site_group.css(".f-c-layout-sidebar__part-title").text

        assert top_group.css(".f-c-layout-sidebar__li:contains(\"Obrázky\")")
                        .css("a")
                        .attribute("href")
                        .value
                        .include?(main_site.domain)
      end
    end
  end

  test "`config.folio_shared_files_between_sites` is true: files are stored always under main_site" do
    # proces of creating file is
    # 1) run before_folio_api_s3_path to get s3_url
    # 2) upload file to s3_url
    # 3) run after_folio_api_s3_path to process file
    # so I will test only 3)
    host_site(site_lvh)
    sign_in superadmin

    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      # klasses Folio::File::Document, Folio::File::Image, Folio::PrivateAttachment
      klass = Folio::File::Image
      s3_name = "#{SecureRandom.hex}_test-#{klass.model_name.singular}.gif" # to avoid cross deletions in parallel tests
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
        sign_in superadmin

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

  test "`config.folio_shared_files_between_sites` is false: console files menu is inside sites block" do
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      [main_site, site_lvh].each do |site|
          host_site(site)
          sign_in superadmin

          # it is redirected to pages: get console_root_url(host: main_site.domain, only_path: false)
          get console_pages_url(host: site.domain, only_path: false)

          assert_response :success, response.body

          site_group = Nokogiri::HTML(response.body).css(".f-c-layout-sidebar__group--expanded").first

          assert_equal site.domain, site_group.css(".f-c-layout-sidebar__part-title").text

          images_link_text = site == main_site ? "Obrázky" : "Images"
          images_node = site_group.css(".f-c-layout-sidebar__li:contains(\"#{images_link_text}\")")
          assert images_node.present?

          assert images_node.css("a")
                            .attribute("href")
                            .value
                            .include?(site.domain)
        end
    end
  end

  test "`config.folio_shared_files_between_sites` is false: files are stored under current_site" do
    host_site(site_lvh)
    sign_in superadmin

    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      # klasses Folio::File::Document, Folio::File::Image, Folio::PrivateAttachment
      klass = Folio::File::Image
      s3_name = "#{SecureRandom.hex}_test-#{klass.model_name.singular}.gif" # to avoid cross deletions in parallel tests
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

  private
    def file_data_in_json(json_body, file)
      json_data = JSON.parse(response.body)["data"]
      json_data.detect { |f_data| f_data["attributes"]["file_name"] == file.file_name }
    end
end
