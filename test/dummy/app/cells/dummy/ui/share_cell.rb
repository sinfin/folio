# frozen_string_literal: true

class Dummy::Ui::ShareCell < ApplicationCell
  def share_links
    [
      {
        icon: :facebook,
        title: t(".facebook"),
        url: facebook_url,
        target: "_blank",
      },
      {
        icon: :messenger,
        title: t(".messenger"),
        url: messenger_url,
        target: "_blank",
      },
      {
        icon: :twitter,
        title: t(".twitter"),
        url: twitter_url,
        target: "_blank",
      },
      {
        icon: :mail,
        title: t(".email"),
        url: mail_url,
      },
    ]
  end

  def facebook_url
    h = { u: request.url, src: "sdkpreparse" }
    "https://www.facebook.com/sharer/sharer.php?#{h.to_query}"
  end

  def messenger_url
    h = { u: request.url }
    "messenger://share/?#{h.to_query}"
  end

  def twitter_url
    h = { url: request.url }
    "https://twitter.com/share?#{h.to_query}"
  end

  def mail_url
    h = { subject: model.try(:title) || "", body: request.url }
    "mailto:?#{h.to_query}"
  end
end
