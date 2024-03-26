//= require folio/i18n

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.CharacterCounter = {}

window.Folio.Input.CharacterCounter.i18n = {
  cs: {
    shortForCharacter: 'zn.'
  },
  en: {
    shortForCharacter: 'ch.'
  }
}

window.Folio.Stimulus.register('f-input-character-counter', class extends window.Stimulus.Controller {
  static values = {
    max: Number
  }

  connect () {
    this.addElementToFormGroup()
  }

  disconnect () {
    this.removeElementFromFormGroup()
  }

  onInput (e) {
    const length = this.element.value.length
    const formGroup = this.element.closest('.form-group')
    const wrap = formGroup.querySelector('.f-input-character-counter-wrap')
    const current = wrap.querySelector('.f-input-character-counter-wrap__current')

    if (this.maxValue) {
      wrap.classList.toggle('text-danger', length > this.maxValue)
    }

    current.innerText = length
  }

  addElementToFormGroup () {
    const formGroup = this.element.closest('.form-group')

    if (!formGroup) {
      throw new Error('Missing parent form-group element.')
    }

    formGroup.style.position = 'relative'

    const existingTexts = formGroup.querySelectorAll('.form-text')

    for (let i = 0; i < existingTexts.length; i++) {
      const existingText = existingTexts[i]
      existingText.style.paddingRight = '75px'
    }

    const wrap = document.createElement('small')

    wrap.classList.add('f-input-character-counter-wrap')
    wrap.classList.add('form-text')
    wrap.style.position = 'absolute'
    wrap.style.right = 0

    const currentLength = this.element.value.length

    const current = document.createElement('span')
    current.classList.add('f-input-character-counter-wrap__current')
    current.innerText = currentLength

    wrap.appendChild(current)

    if (this.maxValue) {
      const max = document.createElement('span')

      max.classList.add('f-input-character-counter-wrap__max')
      max.innerText = ` / ${this.maxValue}`

      wrap.appendChild(max)

      if (currentLength > this.maxValue) {
        wrap.classList.add('text-danger')
      }
    }

    wrap.appendChild(document.createTextNode(` ${Folio.i18n(window.Folio.Input.CharacterCounter.i18n, 'shortForCharacter')}`))

    this.element.insertAdjacentElement('afterend', wrap)
  }

  removeElementFromFormGroup () {
    const formGroup = this.element.closest('.form-group')
    const wrap = formGroup.querySelector('.f-input-character-counter-wrap')

    if (!wrap) return
    if (!wrap.parentNode) return
    wrap.parentNode.removeChild(wrap)
  }
})
