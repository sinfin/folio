# frozen_string_literal: true

require "pagy/extras/i18n"
require "pagy/extras/overflow"
require "pagy/extras/bootstrap"

Pagy::VARS[:overflow_mode] = :empty_page
Pagy::VARS[:items] = 50
Pagy::VARS[:size] = [1, 2, 2, 1]
