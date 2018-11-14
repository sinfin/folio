window.folioConsoleAtom ?= {}

window.folioConsoleAtom.switchModelField = ({ structure, $field, klassFilter }) ->
  if structure
    present = true
    $field.removeAttr('hidden')
    $selects = $field.find('.folio-console-atom-model-select')
    $activeSelects = $selects.filter(klassFilter)

    $selects
      .not($activeSelects)
      .attr('disabled', true)
      .closest('.form-group')
      .attr('hidden', true)

    $activeSelects
      .prop('disabled', false)
      .closest('.form-group')
      .removeAttr('hidden')
      .each -> window.folioConsoleAtom.atomModelContentPrefill($(this))
  else
    present = false
    $field.attr('hidden', true)

  return present
