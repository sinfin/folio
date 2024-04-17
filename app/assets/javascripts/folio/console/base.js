//= require jquery
//= require rails-ujs
//= require popper.min
//= require folio-bootstrap-5/dist/js/bootstrap.min
//= require multiselect/js/jquery.multi-select
//= require js-cookie/src/js.cookie
//= require jquery.kinetic/index
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
//= require folio/s3_upload
//= require folio/message_bus
//= require folio/modal
//= require folio/remote_scripts

//= require folio/lazyload
//= require folio/lightbox
//= require folio/confirm
//= require folio/debounce
//= require folio/throttle
//= require folio/input
//= require folio/player/player
//= require folio/image/image
//= require folio/chart/chart
//= require folio/ui/icon/icon
//= require folio/click_trigger
//= require folio/nested_fields_component
//= require folio/form_to_hash

// must be under folio/input
//= require daterangepicker.min

//= require folio/console/_bootstrap-tabs-lazyload
//= require folio/console/_cocoon-set-position
//= require folio/console/_data-auto-submit
//= require folio/console/_data-change-value
//= require folio/console/_data-cocoon-single-nested
//= require folio/console/_data-destroy-association
//= require folio/console/modules/event_names
//= require folio/console/modules/danger-box-shadow-blink
//= require folio/console/modules/popover
//= require folio/console/modules/dirty-forms
//= require folio/console/modules/with_aside
//= require folio/console/modules/input/url

//= require folio/console/ui/ajax_input_component
//= require folio/console/ui/alert/alert
//= require folio/console/ui/boolean_toggle_component
//= require folio/console/ui/button/button
//= require folio/console/ui/buttons/buttons
//= require folio/console/ui/notification_modal_component
//= require folio/console/ui/tabs_component

//= require folio/console/form_modal_component
//= require folio/console/addresses/fields/fields
//= require folio/console/atoms/layout_switch/layout_switch
//= require folio/console/atoms/locale_switch/locale_switch
//= require folio/console/catalogue/catalogue
//= require folio/console/clipboard_copy/clipboard_copy
//= require folio/console/console_notes/catalogue_tooltip/catalogue_tooltip
//= require folio/console/current_users/console_path_bar/console_path_bar
//= require folio/console/file/picker/document/document
//= require folio/console/file/picker/picker
//= require folio/console/file/picker/thumb/thumb
//= require folio/console/file/preview_reloader/preview_reloader
//= require folio/console/file/processing_notifier/processing_notifier
//= require folio/console/flash/flash
//= require folio/console/form/errors/errors
//= require folio/console/index/filters/filters
//= require folio/console/index/images/images
//= require folio/console/index/position_buttons/position_buttons
//= require folio/console/layout/sidebar/search/search
//= require folio/console/layout/sidebar/sidebar
//= require folio/console/layout/sidebar/title/title
//= require folio/console/lazy_dom/lazy_dom
//= require folio/console/merges/form/row/row
//= require folio/console/merges/index/radios/radios
//= require folio/console/modules/simple-form-with-atoms
//= require folio/console/nested_model_controls/nested_model_controls
//= require folio/console/new_record_modal/new_record_modal
//= require folio/console/private_attachments/single_dropzone/single_dropzone
//= require folio/console/private_attachments_fields_component
//= require folio/console/publishable_inputs/item/item
//= require folio/console/report/report
//= require folio/console/single_file_select/single_file_select
//= require folio/console/site_user_links/fields_component
//= require folio/console/state/state
//= require folio/console/users/invite_and_copy/invite_and_copy

//= require folio/console/main_app

// So that we can use frontend turbolinks-bound scripts
$(document).on('ready', function () {
  $(document).trigger('turbolinks:load')
})
