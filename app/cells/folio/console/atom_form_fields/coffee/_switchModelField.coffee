window.folioConsoleAtom ?= {}

window.folioConsoleAtom.switchModelField = ({ structure, $field, klassFilter }) ->
  if structure
    present = true
    $field.removeAttr('hidden')
    $selects = $field.find('.folio-console-atom-model-select')
    $activeSelects = $selects.filter(klassFilter)

    $selects
      .not($activeSelects)
      .each -> @selectize?.destroy()
      .prop('disabled', true)
      .closest('.form-group')
      .attr('hidden', true)

    $activeSelects
      .prop('disabled', false)
      .each ->
        $this = $(this)
        window.folioConsoleAtom.atomModelContentPrefill($this)
        window.folioConsoleBindSelectize($this)
      .closest('.form-group')
      .removeAttr('hidden')
  else
    present = false
    $field.attr('hidden', true)

  return present
