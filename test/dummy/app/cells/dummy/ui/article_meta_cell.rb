# frozen_string_literal: true

class Dummy::Ui::ArticleMetaCell < ApplicationCell
  def show
    if model[:tag_records].present? || model[:published_at].present?
      render
    end
  end
end
