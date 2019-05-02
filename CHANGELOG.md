# Change Log
All notable changes to this project will be documented in this file.

## 2019-05-02
### Added
- added email richtext via `premailer-rails`

## 2019-04-26
### Added
- `Folio::Audited` version control concern
- `folio_pages_audited` to application config (enables version control for `Folio::Page`)

## 2019-04-18
### Added
- added `devise_invitable` for `Folio::Account`

## 2019-04-17
### Added
- added `autosize: true` option to text inputs (uses JS to autosize the textarea)

## 2019-04-11
### Removed
- removed `current_admin` helper, use `current_account` instead

## 2019-04-05
### Added
- image sitemap concern enabled by default for `Folio::Node`
- automatic file metadata tagging with `exiftool`

## 2019-04-02
### Removed
- Removed obsolete `console_tooltip` helper.

## 2019-03-07
### Added
- `folio_by_scopes_for` to `Folio::Filterable`

### Changed
- console index filters

## 2019-03-04
### Changed
- split `Folio::HasAtoms` to `Folio::HasAtoms::Basic` for single-locale `:atoms` and `Folio::HasAtoms::Localized` for multiple locales (`:cs_atoms`, `:en_atoms`, ...)

## 2019-02-20
### Added
- `Folio::PrivateAttachment` model and `Folio::HasPrivateAttachments` concern

## 2019-02-19
### Added
- `folio_console_sidebar_prepended_link_class_names`, `folio_console_sidebar_appended_link_class_names` and `folio_console_sidebar_runner_up_link_class_names` to application config

## 2019-02-15
### Changed
- Translations are not enabled by default, set `Rails.application.config.folio_pages_translations = true` to enable.
- Pages ancestry is not enabled by default, set `Rails.application.config.folio_pages_ancestry = true` to enable.
- Renamed `folio_nodes` to `folio_pages`, change the STI default to `Folio::Page`.
- Page slugs now must be unique, no scoping.

### Removed
- Removed `Folio::Node`, `Folio::Category` and `Folio::NodeTranslation`.
- Removed `content` from `Folio::Page`.
- Removed `nested_page_path` helper, use `url_for` instead.

## 2019-02-04
### Changed
- Changed simple_form bootstrap 4 config - check forms and add `$enable-validation-icons: false` to sass variables, remove `flex-row` and use `col-auto` instead.

## 2019-01-30
### Changed
- Changed autocomplete syntax to simply `autocomplete: true` or `autocomplete: ['a', 'b']` on string inputs.

## 2019-01-30
### Removed
- Removed default `by_query` scope from `Folio::Filterable` - use custom `PgSearch` instead!

### Changed
- Changed atoms `STRUCTURE[:model]` to use class names (strings), not actual classes.
- Changed redactor fields syntax - dont use redactor class, use `as: :redactor` instead.

## 2019-01-29
### Added
- Added autocomplete input `f.input :field, as: :autocomplete, collection: ['foo', 'bar']`

### Changed
- Changed datetime fields to use date picker by default, removed `date_picker` input.

## 2019-01-28
### Added
- Added `folio_console_dashboard_redirect` config

### Changed
- Changed `folio/console/tagsinput` usage. See source.
- Dropped rails-assets source from Gemfile, using bower for photoswipe.

## 2019-01-22
### Added
- Lazyload functionality, better image helpers - `image_from`, `lazy_image` and `lazy_image_from`.
- Redactor defined links plugin.

## 2019-01-21
### Changed
- Switched to `pagy` from `kaminari` - to update, modify custom controllers (views are shown automatically):
```ruby
@results = Model.all.page(params[:page].to_i || 1)
# change to
@pagy, @results = pagy(Model.all)
```

## 2019-01-14
### Changed
- Changed `bootstrap/` to `folio-bootstrap/scss/` in `app/assets/stylesheets/_custom_bootstrap.sass`
- Changed `filter` in `Folio::Filterable` to `filter_by_params`

## 2019-01-09
### Changed
- Changed `Node.translate` and `NodeTranslation.translate` to return `nil` for missing locale (instead of the original).

## 2019-01-04
### Added
- Added `date_picker` simple form input

## 2018-12-20
### Added
- Added `folio_console_locale` config key, fixed missing translations

## 2018-12-19
### Changed
- Changed `FolioCell` to `Folio::ApplicationCell` and `Folio::ConsoleCell`

## 2018-12-18
### Changed
- Changed `exceptions_app` workflow. Errors are no longer displayed by Folio. Projects should have their own `ErrorsController` which includes `Folio::ErrorsControllerBase` to run the error pages in the `main_app` context.

## 2018-11-19
### Added
- Added `app/assets/stylesheets/folio/console/_main_app.sass`.

## 2018-11-19
### Changed
- Changed `Lead` - `skip_email_validation?` to public

## 2018-11-11
### Added
- Added image `alt` and document `title` fields.

### Changed
- Changed `Atom` structure, see `app/models/folio/atom/base.rb`
  - To migrate the models, you can use the following script. Note that you might have to update views as well!
  ```
    for file in $( find app/models/**/atom/ -type f -name *.rb ); do
      sed -i 's|documents: :single|document: true|g' $file
      sed -i 's|documents: :multi|documents: true|g' $file
      sed -i 's|images: :single|cover: true|g' $file
      sed -i 's|images: :multi|images: true|g' $file
      sed -i 's|def cell_name|def self.cell_name|g' $file
    done
  ```
  If there were `documents: :single` atoms (now `document: true`), run `rake folio:upgrade:atom_document_placements` as well

- Changed console react helpers:
  - Changed `react_image_select(f)` -> `react_picker(f, :cover_placement)`
  - Changed `react_images_select(f)` -> `react_picker(f, :image_placements)`
  - Changed `react_document_select(f, multi: false)` -> `react_picker(f, :document_placement, file_type: 'Folio::Document')`
  - Changed `react_document_select(f, multi: true)` -> `react_picker(f, :document_placements, file_type: 'Folio::Document')`

## 2018-11-09
### Added
- Added proper `traco` support with `Rails.application.config.folio_using_traco`
- Added `folio:traco` generator

## 2018-11-08
### Added
- Added support for `traco`-translated atoms and nodes.
- Added `with_flag` simple form wrapper.

## 2018-11-06
### Added
- Added reCAPTCHA for leads enabled by setting `ENV['RECAPTCHA_SITE_KEY']` and `ENV['RECAPTCHA_SECRET_KEY']`

## 2018-11-01
### Added
- FilePlacement STI
- HasAttachments `has_one_document_placement`
### Removed
- cookie consent

## 2018-10-12
### Added
- Page caching via `actionpack-page_caching`

## 2018-10-02
### Changed
- `:file` dragonfly by default, add `DEV_S3_DRAGONFLY` flag

## 2018-09-14
### Changed
- added `turbo_mode` to `Site` - splitting JS files into `application.js` and `non_turbo.js` is advised
- changed `resources` -> `resource` for `Site` in console

## 2018-09-14
### Removed
- removed `Thumbnails` concern from `Document`

## 2018-09-13
### Changed
- forms utilize the `form_footer` helper
- `Folio::Atom::Text` has `content: :redactor`

## 2018-09-10
### Removed
- removed `Site.current` and make it use `Folio::Singleton`
- removed `Site` relations from `Node` and `Visit`
- removed `Site.scheme` and `Site.url`

## 2018-09-03
### Changed
- added `required: true` to `belongs_to :placement` of `Folio::Atom::Base`
