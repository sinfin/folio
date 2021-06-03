# frozen_string_literal: true

class Dummy::Blog::CategoriesController < ApplicationController
  before_action :find_category, only: [:show, :preview]

  def show
    if @category.published?
      force_correct_path(url_for(@category))
    else
      redirect_to action: :preview
    end
  end

  def preview
    if @category.published?
      redirect_to action: :show
    else
      render :show
    end
  end

  private
    def find_category
      @category = Dummy::Blog::Category.published_or_admin(account_signed_in?)
                                       .includes(cover_placement: :file)
                                       .by_locale(I18n.locale)
                                       .friendly.find(params[:id])
    end
end
