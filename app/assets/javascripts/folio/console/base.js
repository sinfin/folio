//= require jquery
//= require jquery_ujs
//= require folio-bootstrap/dist/js/bootstrap.bundle
//= require moment/min/moment.min
//= require moment/locale/cs
//= require tempusdominus-bs4/build/js/tempusdominus-bootstrap-4
//= require slideout.js/dist/slideout
//= require jquery-debounce/jquery.debounce

//= require jquery-ui/jquery-ui
//= require ilikenwf-nested-sortable/jquery.mjs.nestedSortable
//= require selectize/dist/js/standalone/selectize
//= require selectize-typing-mode
//= require jquery.dirty/dist/jquery.dirty

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
//= require folio/lightbox
//= require folio/console/_flash
//= require folio/console/_data-auto-submit
//= require folio/console/_data-change-value
//= require folio/console/_data-destroy-association
//= require folio/console/_data-cocoon-single-nested
//= require folio/console/_bootstrap-tabs-lazyload
//= require folio/console/_modal-lazyload
//= require folio/console/_modal-html-scroll
//= require folio/console/_cocoon-set-position
//= require folio/console/_cocoon-prompt-file-input
//= require folio/console/_selectize
//= require folio/console/_tabs
//= require folio/console/atom_form_fields/atom_form_fields
//= require folio/console/tagsinput/tagsinput
//= require folio/console/nested_model_controls/nested_model_controls
//= require folio/console/boolean_toggle/boolean_toggle
//= require folio/console/single_file_select/single_file_select
//= require folio/console/react_picker/react_picker
//= require folio/console/menu_tree/menu_tree
//= require folio/console/file_list/file_list
//= require folio/console/index/checkboxes/checkboxes
//= require folio/console/index/position_buttons/position_buttons
//= require folio/console/form/errors/errors
//= require folio/console/modules/_layout
//= require folio/console/modules/_dirty-forms
//= require folio/console/layout/sidebar/search/search

//= require folio/console/simple_form_inputs/_date_time_input
//= require folio/console/simple_form_inputs/_redactor_input
//= require folio/console/simple_form_inputs/_string_input

//= require ./pages_table

//= require folio/console/main_app

// So that we can use frontend turbolinks-bound scripts
$(document).on('ready', function () {
  $(document).trigger('turbolinks:load')
})
