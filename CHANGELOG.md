# Change Log
All notable changes to this project will be documented in this file.

## 2018-11-01
### Added
- FilePlacement STI
- HasAttachments `has_one_document_placement`

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
