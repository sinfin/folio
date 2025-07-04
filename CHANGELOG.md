# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- added `rel` and `target` to allowed rich text attributes
- actions `destroy`, `discard` and `undiscard` are now by default collapsed in console index pages

- `Folio::ElevenLabs::TranscribeSubtitlesJob` for automatic subtitles transcription using ElevenLabs (disabled by default)

## [6.5.1] - 2025-06-18

### Added

- support for custom submit label in `form_footer`
- support for auto-hiding server-rendered flash messages
- `Rails.application.config.folio_photo_archive_enabled` to enable photo archive feature
- added photo archive filtering for image files
- added information display in file modal for photos imported from photo archive

### Fixed

- hiding settings in `form_footer`
- fix merges form using `form_footer` component instead of outdated cell
- handle `HtmlAutoFormat` with `Folio::HtmlSanitization` - add missing attributes on redactor init when only the `f-c-html-auto-format` class remained
- overriden `friendly_id` to use persisted values so that we don't form invalid URLs in console forms

## [6.5.0] - 2025-06-09

### Added

- HTML sanitization of all string/json values using `Folio::HtmlSanitization::Model` concern included on `ApplicationRecord`

## [6.4.1] - 2025-06-09

### Added

- `bottom_html_api_url` to files, used for new `HasSubtitlesFormComponent`

### Changed

- `cstypo` to use U+00A0 instead of nbsp entity, allowing us to remove `html_safe`

## [6.4.0] - 2025-05-15

### Added

- `timeoutable` to `Folio::User` ; session will expire after 30 minutes of inactivity
- `lockable` to `Folio::User` - lock user for 15 minutes after 5 unsuccessful attempts
- password complexity validation to `Folio::User` - allow 8-128 characters, must include special/lower/upper/number if shorter than 48 characters
- recaptcha to users/session/new

### Changed

- whitelist strong params instead of blacklisting - use `folio_using_traco_aware_param_names` for traco-translatable columns, use `additional_*_params` (i.e. `additional_user_params` ) to add more column names to the whitelist
- updated `session_store` config with `expire_after` / `secure` / `httponly` / `same_site`
- use Devise `paranoid` to avoid enumeration

## [6.3.2] - 2025-05-15

### Added
- `Folio::File::Video::HasSubtitles` concern to Video files
- `Rails.application.config.folio_files_video_enabled_subtitle_languages` to set subtitle languages
- `Folio::OpenAi::TranscribeSubtitlesJob` for automatic subtitles transcription using OpenAI Whisper (disabled by default)

- `file_modal_additional_fields` method to files for custom fields in console file modal

### Changed
- use `only_path: true` for file sidebar links when `folio_shared_files_between_sites`
- allow hiding settings and 'share preview' in  `form_footer`

## [6.3.1] - 2025-04-24

### Added
- `set_cache_control_headers` to set `Cache-Control` headers for unpublished records
- console "CurrentUser" controller allowing users to change their e-mail and password

### Changed
- console `preview_url_for` - now defined in `Folio::Console::PreviewUrlFor` and expandable via `Rails.application.config.folio_console_preview_url_for_procs`
- added `:preview` to the console actions default - hide it if URL is not available

### Fixed
- `react_ordered_multiselect` can now show button to fix required field
- setting of `auth_site_id` caching wrong site in `Folio::Current`
- double rendering (devise and Folio) in `require_no_athentication`, when user is signed in

## Removed
- `Folio::Current` override of `reset`

## [6.3.0] - 2025-04-03

### Changed
- changed `Folio::ContentTemplate` to be scoped per-site and allowed site admins to manage them

### Added
- added `folio:content_templates:idp_migrate_to_per_site` rake task to migrate existing content templates to per-site
- added `folio:content_templates:remove_siteless` rake task to remove siteless content templates
- added `upload` icon
- added `active` column to `Folio::EmailTemplate` and possibility to disable specific email templates
- added `Folio::Captcha::HasRecaptchaValidation` concern, used it in `Folio::Users::InvitationsController`

## [6.2.5] - 2025-03-26

### Added
- `:absolute_urls` option to URL inputs
- `f-c-r-ordered-multiselect-app:add-entry` event listener to react ordered multi select
- `Rails.application.config.folio_dragonfly_cwebp_quality` to set webp conversion quality, change default to 90

### Changed
- only broadcast `file_update` message bus message to users currently in console
- pass `message_bus_client_id` during s3 upload and use it to target message bus messages

### Removed
- presigned URLs from serializers

## [6.2.4] - 2025-03-18

### Added
- `:scope_name` option to `folio_console_links_mapping` config

### Changed
- include `id` and `slug` (when possible) in `by_label_query`
- option to hide "subscribe to newsleter" input in  resource form
- pass `:placeholder` to email input

### Fixed
- built react version to include "folio links" changes

## [6.2.3] - 2025-03-17

### Changed
- set default timeouts for Devise actions and display such information in corresponding emails.
   ```
   config.reset_password_within = 6.hours # see as Folio::User.reset_password_within
   config.invite_for = 30.days
   config.confirm_within = 7.days
   ```
- the way we work with links - added a modal for `as: :url` inputs, added `as: :url_json` and switched some atoms to it

## [6.2.2] - 2025-03-11

### Fixed
- added default `folio_pages_autosave` config

## [6.2.1] - 2025-03-10

### Changed
- moved `Folio::Audited` concern module to `Folio::Audited::Model`

## [6.2.0] - 2025-03-10

### Added
- autosave to console - add `Folio::Autosave::Model` to your model
- autoformat for rich text inputs
- `console_preferences` jsonb column to `Folio::User` to store autosave/autoformat preferences
- divider to `Folio::Console::DropdownCell` with optional title
- href to confirm button in `Folio::Console::Ui::NotificationModalComponent`

## [6.1.3] - 2025-02-20

### Fixed
- fixed initial project configuration when project is freshly cloned and set up

## [6.1.2] - 2025-02-18

### Added
- added support for multi-locale `title` attributes in `Folio::AttributeType`

### Changed
- reverted order of loading email templates in `folio:email_templates:idp_seed` task.
  First App, then Folio. This allows overrinding Folio templates in app.

## [6.1.1] - 2025-02-18

### Added
- `text_or_edit_link` in `Folio::Console::CatalogueCell` returns text or link according to ability

### Changed
- updated legacy audited usage on User, SiteUserLink and Address

## [6.1.0] - 2025-02-07

### Changed
- automatically sort nested collection by position if possible in in `Folio::NestedFieldsComponent`
- audited now uses a `Folio::Audited::Audit` with a custom `folio_data` jsonb column used to store data about atoms, attachments and other relations

## [6.0.5] - 2025-02-03

### Added

- tooltip for disabled action

### Changed

- only pass preview token if unpublished in console index actions

## [6.0.4] - 2025-01-13

### Fixed

- fixed clonable config for model Page

## [6.0.3] - 2025-01-08

### Added

- added `RecordBar` component to ui, hook onto atom errors

### Fixed

- fixed simple form with atoms submission when atom form is open

## [6.0.2] - 2025-01-06

- added `Folio::Console::Clonable` concern together with `Folio::Clonable::Cloner` to allow cloning of records

## [6.0.1] - 2024-12-11

### Changed

- changed react lazyloading from `react-lazyload` to native `loading="lazy"`

## 2024-11-20
### Removed
- removed `current_site` helpers - use `Folio::Current.site` everywhere!
- removed `Folio.current_site` - use `Folio::Current.site`
- removed `Folio.main_site` - use `Folio::Current.main_site`
- removed `Folio.site_for_mailers` - use `Folio::Current.site_for_mailers`
- removed `Folio.enabled_site_for_crossdomain_devise` - use `Folio::Current.enabled_site_for_crossdomain_devise`
- removed `Folio.site_for_crossdomain_devise` - use `Folio::Current.site_for_crossdomain_devise`
- removed `current_user` usage - use `Folio::Current.user` everywhere!

## 2024-08-29
### Added
- added `VALID_SITE_TYPES` to atoms allowing to filter by `Folio::Current.site` class

## 2024-07-24
### Changed
- changed `adaptive-title-font-size` to `font-size-adaptive`, added a `fs-adaptive` class name and `adaptive_font_size_class_name` method to `Folio::ApplicationComponent`
### Removed
- removed `folio/mixins/_adaptive_title_font_size.sass`

## 2024-06-28
### Removed
- removed `Rails.application.config.folio_console_ability_lambda`. Use `app/overrides/models/folio/ability_override.rb` in your project instead.
- removed obsolete `Rails.application.config.folio_site_validate_belongs_to_namespace`
### Changed
- changed how sites in tests work. Folio expects your project to have a `ApplicationName::Site` class and `Rails.application.folio_site_default_test_factory` set.

## 2024-06-21
### Added
  - added `Rails.application.config.folio_console_add_locale_to_preview_links` to be used when your app routes are scoped with `scope "/:locale", locale: /#{I18n.available_locales.join('|')}/`

## 2024-03-20
### Changed
  - changed how leads work - set `Rails.application.config.folio_leads_from_component_class_name` to enable them - use `"Folio::Leads::FormComponent"` or your own

## 2024-02-15
### Added
  - added aliased action `:do_anything` (same as `:manage`), into Folio::Ability.
  - added `user.currently_allowed_actions_with(subject, ability_class = nil)`

## 2024-02-15
### Added
- added `Folio::TogglableFieldsComponent`

## 2024-02-08
### Added
- added `folio_nested_fields` using `Folio::NestedFieldsComponent` - use it instead of `cocoon`

## 2024-01-25
### Changed
- removed `private_attachments` and `private_attachments_fields` partials, use `Folio::Console::PrivateAttachmentsFieldsComponent` instead!

## 2023-12-X
### Changed
- authorization to console is done through user login, not account.
### Removed
- Folio::Account after merging into Folio::User (done in migration)

## 2023-12-14
### Changed
- changed `folio/lightbox` - now works via stimulus, using `stimulus_lightbox` and `stimulus_lightbox_item` helpers

## 2023-11-24
### Changed
- ignore `Rails.application.config.folio_site_is_a_singleton` and handle one site application as multisite with one (and main) site
### Removed
- Folio::Subscribable concern

## 2023-11-06
### Changed
- updated `folio-bootstrap-5` to 5.3 - make sure to update your `_custom_bootstrap.sass` based on the one in folio dummy app
- make sure to check your e-mail templates / mailer previews, styles may break

## 2023-10-02
### Changed
- atom and molecule generator now generates components by default - to use cells, pass the `-cell` option
- renamed `cell_options` to `atom_options` in `render_atoms` and `render_atoms_in_molecules`

## 2023-09-27
### Added
- added `render_view_component` to `Folio::ApplicationCell`
- added `Folio::Console::Ui::BooleanToggleComponent`
### Removed
- removed `Folio::Console::BooleanToggleCell` - replace your `folio/console/boolean_toggle` cell calls with `Folio::Console::Ui::BooleanToggleComponent`

## 2023-07-28
### Changed
- version 4.0!

## 2023-07-25
### Changed
- renamed `new_url` to `new_path_name` in index header and new_button

## 2023-05-02
### Changed
- removed `react_picker` and added `file_picker_for_*`

## 2023-04-26
### Added
- added `preview_token` functionality to `Folio::Publishable` concern, added `preview_token` param to pages - add `preview_token` column to your publishable models!

## 2023-04-24
### Changed
- renamed `Folio::Image` to `Folio::File::Image` and `Folio::Document` to `Folio::File::Document`
### Removed
- removed legacy `Folio::ImageHelper`

## 2023-04-21
### Added
- added `Rails.application.config.folio_users_after_impersonate_path_proc` which uses `folio_users_after_impersonate_path` by default
### Removed
- removed `folio/console/tagsinput` cell, use `as: :tags` simple form input instead

## 2023-03-15
### Added
- added `Folio::HasRoles` and used it for `Folio::Account`
### Changed
- use cancancan `accessible_by` in console index actions

## 2023-03-06
### Changed
- moved s3 signer controller out of console
- moved javascript files around

```
folio/console/_flash     -> folio/console/flash
folio/console/_api       -> folio/api
folio/console/_s3-upload -> folio/s3_upload
folio/_message-bus       -> folio/message_bus
```

- started to refactor `Folio::DropzoneCell` to work with direct s3 uploads - needs some styling still

## 2023-02-17
### Added
- added `folio_users_non_get_referrer_rewrite_proc` config to enable rewriting post/patch referrer paths (such as `/orders/confirm`) to relevant get paths (such as `/orders/edit`)

## 2023-02-07
### Changed
- use `:terser` as the default `js_compressor`, remove `Folio::SelectiveUglifier`

## 2023-01-31
### Changed
- `force_correct_path` now ignores get params by default
- dropped the obsolete `preview` actions from controllers and templates

## 2023-01-24
### Changed
- updated omniauth gems and switched to `omniauth-twitter2` - update your ENV accordingly

## 2023-01-18
### Changed
- changed `folio_pages_translations` config to `folio_pages_locales` and updated logic

## 2023-01-13
### Added
- added overridable `acquire_orphan_records!` to `Folio::User`. Use it to acquire relevant records based on the session id before it gets changed by Warden.

## 2023-01-10
### Added
- added `Folio::FilePlacement::OgImage` to default file plcaement types, add `Folio::HasAttachments` and update fallback og:image
- added `copyright_info_source` to `Folio::Site`

## 2023-01-06
### Changed
- reinvite `Folio::User` when signing in using an e-mail of an user with a pending invitation

## 2022-12-20
### Added
- added `splittable_by_attribute` to atoms
- added `source_site` relation to users

## 2022-12-13
### Added
- added `Folio::CacheMethods`

## 2022-12-01
### Added
- added console notifications when editing/updating the same path as a different account (using `console_path` on `Folio::Account`)

## 2022-11-28
### Added
- added `Folio::PerSiteSingleton` and update console to use the locale of `Folio::Current.site`

## 2022-11-14
### Changed
- changed accounts to use `roles` array instead of a `role` string - update abilities in projects if needed!

## 2022-11-03
### Added
- added `default_gravity` to `Folio::File`

## 2022-09-23
### Changed
- refactored console site form - added tab configuration to `Folio::Current.site.console_form_tabs` for easier extending in `main_app`

## 2022-07-19
### Changed
- refactored simple form inputs - check your js/coffee code (especially console) for manual input functionality and update accordingly

## 2022-07-01
### Changed
- gem dependency changed to `s.add_dependency "acts-as-taggable-on", "~> 9.0"` (allowing usage of ActiveRecord 6.1.4 and above)
- version bump to `0.2.0`

## 2022-06-27
### Added
- added `Rails.application.config.folio_users_after_impersonate_path`

## 2022-05-16
### Added
- added `folio:scaffold` generator

## 2022-05-09
### Added
- added `Rails.application.config.folio_console_react_modal_types`

## 2022-05-02
### Changed
- converted email templates generator to `folio:email_templates:idp_seed` rake task

## 2022-05-02
### Changed
- use `:invitable` instead of `:registerable` for folio users
- changed `Rails.application.config.folio_users_registerable` -> `Rails.application.config.folio_users_publicly_invitable`

## 2022-04-25
### Changed
- updated photoswipe and `folio/lightbox` - remove `folio/photoswipe` cell calls

## 2022-04-14
### Removed
- removed `data_for_search` column from atoms

## 2022-03-25
### Changed
- update `folio_console_sidebar_*` config syntax to use hashes with `{ links: [] }`

## 2022-03-24
### Added
- added `Rails.application.config.folio_site_is_a_singleton` and `Folio::Site` STI support

## 2022-03-21
### Added
- added `Folio::ConsoleNote` model and `Folio::HasConsoleNotes` concern

## 2022-02-21
### Added
- added `self.default_atom_values` to atoms

## 2022-02-04
### Added
- added `Rails.application.config.folio_console_ability_lambda` for easier console ability tweaks

## 2022-02-04
### Changed
- added sidekiq web to folio routes, hidden behind an `authenticate` lambda - remove it from application routes!

## 2022-01-31
### Added
- added `through` support for `folio_console_controller_for`

## 2022-01-31
### Changed
- changed the syntax of `FORM_LAYOUT` for atoms - use nested rows/columns hashes

## 2022-01-20
### Changed
- changed api files controllers to use direct s3 upload
- added `file_mime_type` for `Folio::File`, whilst keeping `mime_type` column so that there's not a 500 during deployment - create a per-project migration removing it

## 2022-01-11
### Changed
- changed console flash javascript - upgrade all your JS code using flash (grep `window.FolioConsole.flash` and replace via the new methods defined in `app/assets/javascripts/folio/console/_flash.es6`)

## 2021-12-14
### Changed
- changed `Folio::DragonflyFormatValidation` to not use dragonfly `validates_property` as it tends to ping the image when not needed - make sure you assign mime_type attributes in `before_validation` instead of `before_save` from now on!

## 2021-11-19
### Added
- added `title` to content templates

## 2021-11-18
### Added
- added `email_modal` option handler in state cell - see wiki for more information

## 2021-10-22
### Added
- added `Folio::FriendlyIdForTraco` concern
- added `Folio::HasAncestrySlugForTraco` concern

## 2021-10-21
### Added
- added "collection_actions" to catalogue, See wiki for more information

## 2021-10-20
### Added
- added easy CSV exports via `csv: true` on `folio_console_controller_for`. See CSV wiki for more information.

## 2021-10-13
### Added
- added automatic sortable arrows to catalogue based on klass `sort_by_*` scopes

## 2021-10-07
### Added
- added `private` thumbnails, add `thumbnail_sizes` to session attachments

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
- Changed `bootstrap/` to `folio-bootstrap-4/scss/` in `app/assets/stylesheets/_custom_bootstrap.sass`
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
  - Changed `react_document_select(f, multi: false)` -> `react_picker(f, :document_placement, file_type: 'Folio::File::Document')`
  - Changed `react_document_select(f, multi: true)` -> `react_picker(f, :document_placements, file_type: 'Folio::File::Document')`

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
