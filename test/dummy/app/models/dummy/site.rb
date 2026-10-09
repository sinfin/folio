# frozen_string_literal: true

class Dummy::Site < Folio::Site
  def self.console_sidebar_before_menu_links
    if defined?(Dummy::Blog)
      %w[
        Dummy::Blog::Article
        Dummy::Blog::Author
        Dummy::Blog::Topic
      ]
    end
  end
end
