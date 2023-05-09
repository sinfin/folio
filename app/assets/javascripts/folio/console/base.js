//= require jquery
//= require rails-ujs
//= require popper.min
//= require folio-bootstrap-with-popper-fix
//= require slideout
//= require multiselect/js/jquery.multi-select
//= require js-cookie/src/js.cookie
//= require jquery.kinetic/index
//= require dropzone/dist/dropzone
//= require clipboard/dist/clipboard
//= require strftime
//= require moment/moment
//= require moment/locale/cs

//= require jquery-ui/jquery-ui
//= require selectize
//= require select2/dist/js/select2.full
//= require select2/dist/js/i18n/cs

//= require cocoon
//= require redactor

//= require ./redactor/_cs
//= require ./redactor/_button
//= require ./redactor/_character_counter
//= require ./redactor/_table
//= require ./redactor/_video
//= require ./redactor/_definedlinks
//= require ./redactor/_linksrel
//= require ./redactor/_init

//= require folio/stimulus
//= require folio/api
//= require folio/s3-upload
//= require folio/message-bus

//= require folio/lazyload
//= require folio/lightbox
//= require folio/debounce
//= require folio/throttle
//= require folio/input
//= require folio/player/player
//= require folio/image/image
//= require folio/ui/icon/icon

// must be under folio/input
//= require daterangepicker.min

//= require folio/console/flash

//= require folio/console/_bootstrap-tabs-lazyload
//= require folio/console/_cocoon-set-position
//= require folio/console/_data-auto-submit
//= require folio/console/_data-change-value
//= require folio/console/_data-cocoon-single-nested
//= require folio/console/_data-destroy-association
//= require folio/console/_modal-html-scroll
//= require folio/console/_modal-lazyload
//= require folio/console/_tabs

//= require folio/console/aasm/email_modal/email_modal
//= require folio/console/accounts/invite_and_copy/invite_and_copy
//= require folio/console/atoms/layout_switch/layout_switch
//= require folio/console/atoms/locale_switch/locale_switch
//= require folio/console/boolean_toggle/boolean_toggle
//= require folio/console/catalogue/catalogue
//= require folio/console/clipboard_copy/clipboard_copy
//= require folio/console/console_notes/catalogue_tooltip/catalogue_tooltip
//= require folio/console/current_accounts/console_path_bar/console_path_bar
//= require folio/console/file/picker/document/document
//= require folio/console/file/picker/picker
//= require folio/console/file/picker/thumb/thumb
//= require folio/console/form/errors/errors
//= require folio/console/index/filters/filters
//= require folio/console/index/header/header
//= require folio/console/index/images/images
//= require folio/console/index/position_buttons/position_buttons
//= require folio/console/layout/sidebar/search/search
//= require folio/console/layout/sidebar/sidebar
//= require folio/console/lazy_dom/lazy_dom
//= require folio/console/merges/form/row/row
//= require folio/console/merges/index/radios/radios
//= require folio/console/modules/_dirty-forms
//= require folio/console/modules/_layout
//= require folio/console/modules/_multiselect
//= require folio/console/modules/_with-aside
//= require folio/console/modules/simple-form-with-atoms
//= require folio/console/nested_model_controls/nested_model_controls
//= require folio/console/new_record_modal/new_record_modal
//= require folio/console/private_attachments/fields/fields
//= require folio/console/private_attachments/single_dropzone/single_dropzone
//= require folio/console/publishable_inputs/item/item
//= require folio/console/single_file_select/single_file_select
//= require folio/console/state/state

//= require ./pages_table

//= require folio/console/main_app

// So that we can use frontend turbolinks-bound scripts
$(document).on('ready', function () {
  $(document).trigger('turbolinks:load')
})
