# frozen_string_literal: true

class Dummy::UiController < ApplicationController
  def show
    @actions = %i[
      buttons
      icons
      typo
    ]
  end

  def buttons
    ary = [
      { variant: :primary, label: "Primary" },
      { variant: :secondary, label: "Secondary" },
      { variant: :success, label: "Success" },
      { variant: :info, label: "Info" },
      { variant: :warning, label: "Warning" },
      { variant: :danger, label: "Danger" },
      { variant: :info, loader: true, label: "Loader" },
    ]

    @buttons_model = {}

    {
      "Regular" => {},
      "Small" => { size: :sm },
      "Large" => { size: :lg },
      "Disabled" => { disabled: true },
    }.each do |title, h|
      @buttons_model[title] = [
        ary.map { |b| b.merge(h) },
        ary.map { |b| b.merge(h).merge(outline: true) },
        ary.map { |b| b.merge(h).merge(icon: :alert_triangle) },
        ary.map { |b| b.merge(h).merge(icon: :alert_triangle, label: nil) },
      ]
    end
  end
end
