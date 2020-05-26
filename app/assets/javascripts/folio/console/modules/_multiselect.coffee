ESCAPE_KEY = 27

text = (str) ->
  """
    <small class="text-muted d-block mb-1">#{str}</small>
    <input class="form-control form-control-sm mb-2 ms-filter" type="text">
  """

if String.prototype.normalize
  normalize = (str) ->
    str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
else
  normalize = (str) -> str.toLowerCase()

bindMultiSelects = ->
  $('select[multiple]')
    .not('.f-c-js-manual')
    .not('.f-c-collection-remote-select-input')
    .multiSelect
      selectableHeader: text(window.FolioConsole.translations.selectable)
      selectionHeader: text(window.FolioConsole.translations.selected)

if Turbolinks?
  $(document)
    .on 'turbolinks:load', bindMultiSelects

    .on 'turbolinks:before-cache', ->
      $('select[multiple]').multiSelect('destroy')

else
  $ bindMultiSelects

$(document)
  .on 'keyup', '.ms-filter', (e) ->
    $input = $(this)

    $input.val('') if e.keyCode is ESCAPE_KEY

    value = normalize($.trim($input.val()))
    $list = $input.next('.ms-list')

    if value.length
      $list
        .children('li')
        .each ->
          @hidden = normalize(@textContent).indexOf(value) is -1
          return true

    else
      $list.children('li').prop('hidden', false)
