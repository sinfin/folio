# frozen_string_literal: true

class Dummy::Blog::TopicsController < Dummy::Blog::BaseController
  def show
    folio_run_unless_cached(["blog/topics#show", params[:id], params[:page]] + cache_key_base) do
      @topic = Dummy::Blog::Topic.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                                 .by_locale(I18n.locale)
                                 .by_site(Folio::Current.site)
                                 .friendly.find(params[:id])

      unless force_correct_path(url_for(@topic))
        set_meta_variables(@topic)
        add_breadcrumb_on_rails @topic.to_label
      end
    end
  end
end
