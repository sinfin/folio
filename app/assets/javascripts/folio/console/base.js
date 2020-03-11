//= require jquery
//= require rails-ujs
//= require folio-bootstrap/dist/js/bootstrap.bundle
//= require moment/moment
//= require moment/locale/cs
//= require eonasdan-bootstrap-datetimepicker/build/js/bootstrap-datetimepicker.min
//= require slideout.js/dist/slideout
//= require jquery-debounce/jquery.debounce
//= require multiselect/js/jquery.multi-select
//= require autosize/dist/autosize
//= require spectrum/spectrum
//= require js-cookie/src/js.cookie
//= require cleave.js/dist/cleave

//= require jquery-ui/jquery-ui
//= require selectize/dist/js/standalone/selectize

//= require cocoon
//= require redactor

//= require ./redactor/_cs
//= require ./redactor/_imagemanager
//= require ./redactor/_video
//= require ./redactor/_table
//= require ./redactor/_button
//= require ./redactor/_definedlinks
//= require ./redactor/_init

//= require folio/cable
//= require folio/lazyload
//= require folio/lightbox
//= require folio/console/_bootstrap-tabs-lazyload
//= require folio/console/_cocoon-prompt-file-input
//= require folio/console/_cocoon-set-position
//= require folio/console/_data-auto-submit
//= require folio/console/_data-change-value
//= require folio/console/_data-cocoon-single-nested
//= require folio/console/_data-destroy-association
//= require folio/console/_flash
//= require folio/console/_modal-html-scroll
//= require folio/console/_modal-lazyload
//= require folio/console/_tabs

//= require folio/console/atoms/layout_switch/layout_switch
//= require folio/console/atoms/locale_switch/locale_switch
//= require folio/console/atoms/settings_header/settings_header
//= require folio/console/boolean_toggle/boolean_toggle
//= require folio/console/file_list/file_list
//= require folio/console/form/errors/errors
//= require folio/console/index/filters/filters
//= require folio/console/index/header/header
//= require folio/console/index/images/images
//= require folio/console/index/position_buttons/position_buttons
//= require folio/console/layout/sidebar/search/search
//= require folio/console/merges/form/row/row
//= require folio/console/merges/index/radios/radios
//= require folio/console/modules/_dirty-forms
//= require folio/console/modules/_layout
//= require folio/console/modules/_multiselect
//= require folio/console/modules/simple-form-with-atoms
//= require folio/console/nested_model_controls/nested_model_controls
//= require folio/console/new_record_modal/new_record_modal
//= require folio/console/pagination/pagination
//= require folio/console/publishable_inputs/publishable_inputs
//= require folio/console/react_picker/react_picker
//= require folio/console/single_file_select/single_file_select
//= require folio/console/tagsinput/tagsinput

//= require folio/console/simple_form_inputs/_collection_select_input
//= require folio/console/simple_form_inputs/_color_input
//= require folio/console/simple_form_inputs/_date_time_input
//= require folio/console/simple_form_inputs/_redactor_input
//= require folio/console/simple_form_inputs/_string_input
//= require folio/console/simple_form_inputs/_text_input

//= require ./pages_table

//= require folio/console/main_app

// So that we can use frontend turbolinks-bound scripts
$(document).on('ready', function () {
  $(document).trigger('turbolinks:load')
})
