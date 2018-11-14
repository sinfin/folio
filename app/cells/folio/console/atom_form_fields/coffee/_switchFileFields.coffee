window.folioConsoleAtom ?= {}

window.folioConsoleAtom.switchFileFields = ({ $fields, structure }) ->
  present = false

  for key in ['cover', 'document', 'images', 'documents']
    $field = $fields.filter(".folio-console-atom-fields--#{key}")

    if structure[key]
      present = true
      $field.removeAttr('hidden')
    else
      $field.attr('hidden', true)

  return present

