# frozen_string_literal: true

class Dummy::Blog::Topics::TagsListComponent < ApplicationComponent
  def initialize(topics:)
    @topics = topics
  end
end
