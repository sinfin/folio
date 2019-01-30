# Change Log
All notable changes to this project will be documented in this file.

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
