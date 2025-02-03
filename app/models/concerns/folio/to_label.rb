# frozen_string_literal: true

module Folio::ToLabel
  extend ActiveSupport::Concern

  included do
    pg_search_scope :by_title_query,
                    against: %i[title],
                    ignoring: :accents,
                    using: {
                      tsearch: { prefix: true }
                    }

    scope :by_label_query, -> (query) do
      if column_names.include?("title")
        by_title_query(query)
      elsif respond_to?(:by_query)
        by_query(query)
      else
        none
      end
    end
  end

  def to_label
    try(:title).presence ||
    try(:name).presence ||
    self.class.model_name.human
  end

  def to_console_label
    to_label
  end

  def to_autocomplete_label
    to_label
  end
end
