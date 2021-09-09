# Change Log
All notable changes to this project will be documented in this file.

## 2021-09-09
### Added
- added search generator and UI

## 2021-08-20
### Added
- added `VALID_PLACEMENT_TYPES` to atoms, validate placement method

## 2021-08-09
### Added
- added `phone` to `Folio::User`

## 2021-08-03
### Changed
- updated rails to 6.1.4

## 2021-07-16
### Added
- added Folio::HasAncestrySlug concern

## 2021-06-23
### Added
- added development s3 fetching via DRAGONFLY_PRODUCTION_S3_URL_BASE in ENV
### Changed
- changed folio/thumbnails to update image-to-be-thumbnailed with `started_generating_at` to avoid creating duplicate generate jobs

## 2021-06-11
### Added
- added Folio::HasSanitizedFields concern

## 2021-06-02
### Added
- added header message to Site

## 2021-04-22
### Added
- added UI generator, refactor dummy assets usage
- added assets generator
### Changed
- added plenty of prepared_atom templates

## 2021-04-21
### Added
- added `Folio::Mailchimp::Api` helper class
- added subscribable associtation to newsletter subscriptions & `Folio::HasNewsletterSubscription` concern
### Changed
- mark `Folio::Subscribable` as deprecated

## 2020-03-09
### Added
- added `folio:console:catalogue` generator

## 2020-03-03
### Added
- added `react_ordered_multiselect` for has_many through relations with positionable

## 2020-02-24
### Removed
- removed `Folio::Atom::Text` and `Folio::Atom::Title`
### Added
- added folio:prepared_atom generator
- started creating/updating `config/locales/atom.LOCALE.yml` for atom model names in generators

## 2020-02-23
### Added
- added users and addresses
- added custom devise views for user

## 2020-02-17
### Added
- added `url` type to atom structure

## 2020-02-11
### Added
- added `redactor: :perex` and `folio_pages_perex_richtext` configuration

## 2020-02-09
### Added
- added transportable functionality - download to yaml/override from yaml

## 2020-02-04
### Removed
- removed ahoy

## 2020-12-09
### Added
- [email templates](https://github.com/sinfin/folio/wiki/Email-templates)

## 2020-12-03
### Added
- private attachments api controller
- private attachments single_dropzone cell
- private_attachment method to catalogue

## 2020-12-02
### Added
- respect `:modal` option on AASM events

## 2020-11-25
### Changed
- updated `:date` and `:datetime` atoms to store the value as a date/datettime instead of a string

## 2020-11-16
### Changed
- updated console cell styles import - add `@import '../../../../cells/folio/console/**/*'` to `app/assets/stylesheets/folio/console/_main_app.sass`

## 2020-11-05
### Added
- added `FORM_LAYOUT` to atoms

## 2020-10-06
### Changed
- updated lead form cell - changed from `folio/lead_form` to `folio/leads/form` and `.folio-lead-form` to `.folio-leads-form`

## 2020-09-21
### Added
- added session attachment model and views

## 2020-09-16
### Added
- added ancestry support to catalogue via `ancestry: true` option

## 2020-09-01
### Removed
- removed `:page` pseudo relation from menu items and updated to_label accordingly
- removed menu items STI

## 2020-08-26
### Changed
- updated bootstrap to 4.5.2

## 2020-08-18
### Changed
- changed rubocop and guard configuration, see `install_generator.rb` for proper gems and templates for guard/rubocop configs

## 2020-08-05
### Added
- extended remote collection select input to accept a hash with scope names `remote: { scope: :my_scope, order_scope: :my_order_scope }`

## 2020-08-04
### Added
- added table style and config for `show_for`

## 2020-08-03
### Removed
- removed `index_show_for`

### Added
- added `catalogue` instead

## 2020-07-22
### Removed
- removed `turbo_mode` from `Site`
- removed `non_turbo.js`

## 2020-05-06
### Added
- added `folio:pg_search_index_migration` generator
- added `folio_unaccent` – immutable & indexable version of unaccent function

## 2019-08-06
### Added
- added `Folio::DownloadsController` and `download_path`
- added `Folio::HasHashId` concern
- added `hash_id` to folio files

## 2019-06-21
### Added
- added `Folio::Console::Api::BaseController`
- added `fast_jsonapi` gem

### Removed
- removed `active_model_serializers` gem

### Changed
- moved location controller to api namespace, update your decorators!
- updated image & document routes

## 2019-05-24
### Added
- added `email_from`, `system_email` and `system_email_copy` to `Site`

## 2019-05-15
### Added
- `Folio::Subscribable` concern
- `Folio::Mailchimp::SubscribeJob`

### Removed
- `folio:export:newsletter` rake task

## 2019-05-02
### Added
- added `public?` class method to `Page` to disable access to homepage and such via pages controller

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
