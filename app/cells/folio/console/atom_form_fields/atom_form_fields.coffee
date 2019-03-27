#= require ./coffee/_atomModelContentPrefill
#= require ./coffee/_switchStringField
#= require ./coffee/_switchRedactorField
#= require ./coffee/_switchModelField
#= require ./coffee/_switchFileFields

atomFormBySelect = ($element) ->
  klass = $element.val()
  $fields = $element.closest('.nested-fields')
  $fieldset = $fields.closest('.f-c-atom-form-fields__wrap')
  $wrap = $fields.find('.folio-console-atom-main-fields').first()
  presence = []
  klassFilter = """[data-class="#{klass}"]"""

  structure = $fieldset.data('structures')[klass]
  placeholders = $fieldset.data('placeholders')[klass]

  presence.push window.folioConsoleAtom.switchStringField
    structure: structure.title
    $field: $fields.find('.folio-console-atom-title')
    placeholder: placeholders.title

  presence.push window.folioConsoleAtom.switchRedactorField
    structure: structure.content
    $field: $fields.find('.folio-console-atom-content')
    placeholder: placeholders.content

  presence.push window.folioConsoleAtom.switchRedactorField
    structure: structure.perex
    $field: $fields.find('.folio-console-atom-perex')
    placeholder: placeholders.perex

  presence.push window.folioConsoleAtom.switchModelField
    structure: structure.model
    $field: $fields.find('.folio-console-atom-model .form-group')
    $fieldset: $fieldset
    klass: klass

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

$(document)
  .on 'cocoon:after-insert', '.f-c-atom-form-fields__wrap', (e, insertedItem) ->
    atomFormBySelect($(insertedItem).find('.folio-console-atom-type-select'))

  .on 'change', '.folio-console-atom-type-select', ->
    console.log(this)
    atomFormBySelect($(this))

  .on 'change', '.folio-console-atom-model-select', ->
    window.folioConsoleAtom.atomModelContentPrefill($(this))

  .on 'focus', '.f-c-atom-form-fields .form-control', ->
    $wrap = $(this).closest('.f-c-atom-form-fields')
    $wrap.addClass('f-c-atom-form-fields--focused')

  .on 'blur', '.f-c-atom-form-fields .form-control', ->
    $wrap = $(this).closest('.f-c-atom-form-fields')
    $wrap.removeClass('f-c-atom-form-fields--focused')

  .on 'ready', ->
    $('.folio-console-atom-type-select').each ->
      atomFormBySelect($(this))
