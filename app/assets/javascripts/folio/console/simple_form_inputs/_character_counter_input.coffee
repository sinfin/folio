CH_C_SELECTOR = '.f-c-string-input--character-counter'

templateBasic = (count) ->
  """
    <span class="f-c-string-input-character-counter small">
      <span class="f-c-string-input-character-counter__current">#{count}</span>
      #{window.FolioConsole.translations.shortForCharacter}
    </span>
  """

templateMax = (count, max) ->
  """
    <span class="f-c-string-input-character-counter small">
      <span class="f-c-string-input-character-counter__current">#{count}</span>
      /
      <span class="f-c-string-input-character-counter__max">
        #{max}
        #{window.FolioConsole.translations.shortForCharacter}
      </span>
    </span>
  """

handle = (e) ->
  $this = $(this)
  $this
    .closest('.f-c-string-input-character-counter__parent')
    .find('.f-c-string-input-character-counter__current')
    .text $this.val().length

window.folioConsoleBindCharacterCounterInput = ($elements) ->
  $elements.each ->
    $input = $(this)
    $group = $input.closest('.form-group')
    $group.addClass('f-c-string-input-character-counter__parent')
    $formText = $group.find('.form-text')
    if $formText.length is 0
      $formText = $('<small class="form-text text-muted f-c-string-input-character-counter__form-text">&nbsp;</small>')
      $group.append($formText)

    max = parseInt($input.data('character-counter'))
    count = $input.val().length
    if isNaN(max)
      $group.append(templateBasic(count))
    else
      $group.append(templateMax(count, max))

    $input.on 'keyup.fcStringInputCharacterCounter change.fcStringInputCharacterCounter', handle

window.folioConsoleUnbindCharacterCounterInput = ($elements) ->
  $elements.each ->
    $input = $(this)
    $input
      .off 'keyup.fcStringInputCharacterCounter change.fcStringInputCharacterCounter', handle
      .closest('.form-group')
      .removeClass('f-c-string-input-character-counter__parent')
      .find('.f-c-string-input-character-counter, .f-c-string-input-character-counter__form-text')
      .remove()

window.folioConsoleBindCharacterCounterInputsIn = ($wrap) ->
  window.folioConsoleBindCharacterCounterInput $wrap.find(CH_C_SELECTOR)

window.folioConsoleUnbindCharacterCounterInputsIn = ($wrap) ->
  window.folioConsoleUnbindCharacterCounterInput $wrap.find(CH_C_SELECTOR)

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    window.folioConsoleBindCharacterCounterInput(insertedItem.find(CH_C_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    window.folioConsoleUnbindCharacterCounterInput(item.find(CH_C_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      window.folioConsoleBindCharacterCounterInput($(CH_C_SELECTOR))

    .on 'turbolinks:before-cache', ->
      window.folioConsoleUnbindCharacterCounterInput($(CH_C_SELECTOR))

else
  $ ->
    window.folioConsoleBindCharacterCounterInput($(CH_C_SELECTOR))
