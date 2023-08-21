# frozen_string_literal: true

class Dummy::UiController < ApplicationController
  def show
    @actions = %i[
      buttons
    ].sort
  end

  def buttons
    @buttons_model = [
      { variant: :primary, label: "Primary" },
      { variant: :secondary, label: "Secondary" },
      { variant: :tertiary, label: "Tertiary" },
      { variant: :success, label: "Success" },
      { variant: :info, label: "Info" },
      { variant: :warning, label: "Warning" },
      { variant: :danger, label: "Danger" },
      { variant: :info, loader: true, label: "Loader" },
    ]
  end
end
