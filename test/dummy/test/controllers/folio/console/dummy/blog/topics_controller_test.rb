# frozen_string_literal: true

require "test_helper"

class Folio::Console::Dummy::Blog::TopicsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Dummy::Blog::Topic])

    assert_response :success

    create(:dummy_blog_topic)

    get url_for([:console, Dummy::Blog::Topic])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Dummy::Blog::Topic, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:dummy_blog_topic)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "console member urls use database id" do
    model = create(:dummy_blog_topic, slug: "console-topic")

    assert_includes url_for([:edit, :console, model]), "/#{model.id}/edit"
    assert_includes url_for([:console, model]), "/#{model.id}"
    assert_no_match "/console-topic", url_for([:edit, :console, model])
    assert_no_match "/console-topic", url_for([:console, model])
  end

  test "public urls still use friendly id slug" do
    model = create(:dummy_blog_topic, slug: "public-topic")

    assert_includes url_for(model), "/blog/topics/public-topic"
    assert_no_match "/#{model.id}", url_for(model)
  end

  test "old slug console edit urls redirect to database id url" do
    model = create(:dummy_blog_topic, slug: "old-console-topic")

    get "/console/dummy/blog/topics/old-console-topic/edit"

    assert_redirected_to url_for([:edit, :console, model])
  end

  test "create" do
    params = build(:dummy_blog_topic).serializable_hash
    assert_equal(0, Dummy::Blog::Topic.count)

    post url_for([:console, Dummy::Blog::Topic]), params: {
      dummy_blog_topic: params,
    }

    assert_equal(1, Dummy::Blog::Topic.count, "Creates record")
  end

  test "update" do
    model = create(:dummy_blog_topic)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      dummy_blog_topic: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "id lookup is unambiguous for duplicate slugs in different sites" do
    other_site = create_site(attributes: { domain: "other.example.com" }, force: true)
    current_site_topic = create(:dummy_blog_topic, slug: "shared-topic", title: "Current site")
    other_site_topic = create(:dummy_blog_topic, slug: "shared-topic", title: "Other site", site: other_site)
    controller = Folio::Console::Dummy::Blog::TopicsController.new

    record = controller.send(:find_console_resource,
                             Dummy::Blog::Topic.by_site([site]),
                             current_site_topic.id.to_s)
    record.update!(title: "Updated current site")

    assert_equal("Updated current site", current_site_topic.reload.title)
    assert_equal("Other site", other_site_topic.reload.title)
    assert_raises(ActiveRecord::RecordNotFound) do
      controller.send(:find_console_resource,
                      Dummy::Blog::Topic.by_site([site]),
                      current_site_topic.slug)
    end
  end

  test "destroy" do
    model = create(:dummy_blog_topic)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Dummy::Blog::Topic])
    assert_not(Dummy::Blog::Topic.exists?(id: model.id))
  end
end
