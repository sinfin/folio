# frozen_string_literal: true

Pagy::OPTIONS[:limit] = 50
Pagy::OPTIONS[:slots] = 9

pagy_locale_paths = Dir[Pagy::ROOT.join("locales/*.yml")]
Pagy.translate_with_the_slower_i18n_gem!

# Let Folio and host-app translations override Pagy's bundled dictionaries.
I18n.load_path.reject! { |path| pagy_locale_paths.include?(path.to_s) }
I18n.load_path.unshift(*pagy_locale_paths)
