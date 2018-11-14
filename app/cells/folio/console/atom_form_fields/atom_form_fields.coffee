#= require ./coffee/_atomModelContentPrefill
#= require ./coffee/_switchStringField
#= require ./coffee/_switchRedactorField
#= require ./coffee/_switchModelField
#= require ./coffee/_switchFileFields

atomFormBySelect = ($element) ->
  klass = $element.val()
  structure = $element.find(':selected').data('atom-structure')
  $fields = $element.closest('.nested-fields')
  $wrap = $fields.find('.folio-console-atom-main-fields').first()
  presence = []
  klassFilter = """[data-class="#{klass}"]"""

  placeholders = $fields.data('placeholders')[klass]

  presence.push window.folioConsoleAtom.switchStringField
    structure: structure.title
    $field: $fields.find('.folio-console-atom-title')
    placeholders: placeholders

  presence.push window.folioConsoleAtom.switchRedactorField
    structure: structure.content
    $field: $fields.find('.folio-console-atom-content')
    placeholders: placeholders

  presence.push window.folioConsoleAtom.switchRedactorField
    structure: structure.perex
    $field: $fields.find('.folio-console-atom-perex')
    placeholders: placeholders

  presence.push window.folioConsoleAtom.switchModelField
    structure: structure.model
    $field: $fields.find('.folio-console-atom-model')
    klassFilter: klassFilter

  presence.push window.folioConsoleAtom.switchFileFields
    $fields: $fields.find('.folio-console-atom-fields')
    structure: structure

  $fields
    .find('.folio-console-atom-hint')
    .attr('hidden', true)
    .filter(klassFilter)
    .removeAttr('hidden')

  if presence.indexOf(true) is -1
    $wrap.attr('hidden', true)
  else
    $wrap.removeAttr('hidden')

$(document).on 'cocoon:after-insert', '#atoms', (e, insertedItem) ->
  atomFormBySelect($(insertedItem).find('.folio-console-atom-type-select'))

$(document).on 'change', '.folio-console-atom-type-select', ->
  atomFormBySelect($(this))

$(document).on 'change', '.folio-console-atom-model-select', ->
  window.folioConsoleAtom.atomModelContentPrefill($(this))

$(document).on 'focus', '.folio-console-atom-form-fields .form-control', ->
  $wrap = $(this).closest('.folio-console-atom-form-fields')
  $wrap.addClass('folio-console-atom-form-fields--focused')

$(document).on 'blur', '.folio-console-atom-form-fields .form-control', ->
  $wrap = $(this).closest('.folio-console-atom-form-fields')
  $wrap.removeClass('folio-console-atom-form-fields--focused')

$('.folio-console-atom-type-select').each -> atomFormBySelect($(this))
