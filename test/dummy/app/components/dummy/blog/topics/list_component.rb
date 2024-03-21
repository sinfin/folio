# frozen_string_literal: true

class Dummy::Blog::Topics::ListComponent < ApplicationComponent
  def initialize(topics:)
    @topics = topics
  end
end
