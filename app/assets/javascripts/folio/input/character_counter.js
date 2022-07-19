//= require folio/input/_framework

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.CharacterCounter = {}

window.Folio.Input.CharacterCounter.SELECTOR = '.f-input--character-counter'

window.Folio.Input.CharacterCounter.templateBasic = (count) => (
  `<span class="f-input-character-counter-wrap small">
     <span class="f-input-character-counter-wrap__current">${count}</span>
     ${window.FolioConsole.translations.shortForCharacter}
   </span>`
)

window.Folio.Input.CharacterCounter.templateMax = (count, max) => (
  `<span class="f-input-character-counter-wrap small">
     <span class="f-input-character-counter-wrap__current">${count}</span>
     /
     <span class="f-input-character-counter-wrap__max">
       ${max}
       ${window.FolioConsole.translations.shortForCharacter}
     </span>
   </span>`
)

window.Folio.Input.CharacterCounter.onKeyupOrChange = (e) => {
  const $this = $(e.currentTarget)

  $this
    .closest('.f-input-character-counter-wrap__parent')
    .find('.f-input-character-counter-wrap__current')
    .text($this.val().length)
}

window.Folio.Input.CharacterCounter.bind = (input) => {
  const $input = $(input)
  const $group = $input.closest('.form-group')

  $group.addClass('f-input-character-counter-wrap__parent')

  let $formText = $group.find('.form-text')

  if ($formText.length === 0) {
    $formText = $('<small class="form-text text-muted f-input-character-counter-wrap__form-text">&nbsp;</small>')
    $group.append($formText)
  }

  const max = parseInt($input.data('character-counter'))

  const count = $input.val().length

  if (isNaN(max)) {
    $group.append(window.Folio.Input.CharacterCounter.templateBasic(count))
  } else {
    $group.append(window.Folio.Input.CharacterCounter.templateMax(count, max))
  }

  $input.on('keyup.fcStringInputCharacterCounter change.fcStringInputCharacterCounter',
    window.Folio.Input.CharacterCounter.onKeyupOrChange)
}

window.Folio.Input.CharacterCounter.unbind = (input) => {
  const $input = $(input)

  $input
    .off('keyup.fcStringInputCharacterCounter change.fcStringInputCharacterCounter',
      window.Folio.Input.CharacterCounter.onKeyupOrChange)
    .closest('.form-group')
    .removeClass('f-input-character-counter-wrap__parent')
    .find('.f-input-character-counter-wrap, .f-input-character-counter-wrap__form-text')
    .remove()
}

window.Folio.Input.framework(window.Folio.Input.CharacterCounter)
