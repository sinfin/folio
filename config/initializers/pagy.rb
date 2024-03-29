# frozen_string_literal: true

require "pagy/extras/bootstrap"
require "pagy/extras/i18n"
require "pagy/extras/overflow"
require "pagy/extras/trim"

Pagy::DEFAULT[:overflow] = :last_page
Pagy::DEFAULT[:items] = 50
Pagy::DEFAULT[:size] = [1, 2, 2, 1]
