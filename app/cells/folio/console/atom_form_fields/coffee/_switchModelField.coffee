window.folioConsoleAtom ?= {}

window.folioConsoleAtom.switchModelField = ({ structure, $field, $fieldset, klass }) ->
  if structure
    present = true

    models = $fieldset.data('models')
    model = models[klass]

    $select = $field.find('.form-control')
    oldValue = $select.val()

    $select.html('')

    options = model.map (ary) ->
      $option = $('<option />')
      $option.html(ary[0])
      $option.prop('value', ary[1])
      $option.prop('selected', true) if ary[1] is oldValue
      $select.append($option)

    $select.prop('disabled', false)
    $field.removeAttr('hidden')
  else
    present = false
    $field
      .attr('hidden', true)
      .find('.form-control')
      .prop('disabled', true)

  return present
