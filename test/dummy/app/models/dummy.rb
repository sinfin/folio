# frozen_string_literal: true

module Dummy
  def self.rails_paths
    h = {}

    %i[
      root_path
    ].each do |key|
      h[key] = I18n.t("dummy.menu.base.#{key}", default: key.to_s)
    end

    h
  end
end
