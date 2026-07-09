//= require folio/i18n
//= require folio/word_count

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
    currentCountLimit: Number,
    max: Number
  }

  connect () {
    this.addElementToFormGroup()
    this.counterElementAdded = true
  }

  disconnect () {
    this.counterElementAdded = false
    this.removeElementFromFormGroup()
  }

  maxValueChanged (value, previousValue) {
    if (!this.counterElementAdded) return
    if (value === previousValue) return

    this.updateMaxElement()
  }

  onInput (e) {
    const length = this.currentLength()
    const formGroup = this.element.closest('.form-group')
    const wrap = formGroup.querySelector('.f-input-character-counter-wrap')
    const current = wrap.querySelector('.f-input-character-counter-wrap__current')

    this.updateDangerClass(wrap, length)
    current.innerText = this.currentCountText(length)
  }

  addElementToFormGroup () {
    const formGroup = this.element.closest('.form-group')

    if (!formGroup) {
      throw new Error('Missing parent form-group element.')
    }

    const existingWrap = formGroup.querySelector('.f-input-character-counter-wrap')

    if (existingWrap) {
      existingWrap.remove()
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

    const currentLength = this.currentLength()

    const current = document.createElement('span')
    current.classList.add('f-input-character-counter-wrap__current')
    current.innerText = this.currentCountText(currentLength)

    wrap.appendChild(current)

    if (this.hasActiveMaxValue()) {
      const max = document.createElement('span')

      max.classList.add('f-input-character-counter-wrap__max')
      max.innerText = ` / ${this.maxValue}`

      wrap.appendChild(max)

      this.updateDangerClass(wrap, currentLength)
    }

    wrap.appendChild(document.createTextNode(` ${window.Folio.i18n(window.Folio.Input.CharacterCounter.i18n, 'shortForCharacter')}`))

    this.element.insertAdjacentElement('afterend', wrap)
  }

  updateMaxElement () {
    const formGroup = this.element.closest('.form-group')
    const wrap = formGroup.querySelector('.f-input-character-counter-wrap')
    const max = wrap.querySelector('.f-input-character-counter-wrap__max')

    if (this.hasActiveMaxValue()) {
      if (max) {
        max.innerText = ` / ${this.maxValue}`
      } else {
        this.insertMaxElement(wrap)
      }
    } else if (max) {
      max.remove()
    }

    this.updateDangerClass(wrap, this.currentLength())
  }

  insertMaxElement (wrap) {
    const max = document.createElement('span')

    max.classList.add('f-input-character-counter-wrap__max')
    max.innerText = ` / ${this.maxValue}`

    const current = wrap.querySelector('.f-input-character-counter-wrap__current')
    current.insertAdjacentElement('afterend', max)
  }

  updateDangerClass (wrap, length) {
    wrap.classList.toggle('text-danger', this.hasActiveMaxValue() && length > this.maxValue)
  }

  currentCountText (length) {
    if (this.hasCurrentCountLimitValue && length > this.currentCountLimitValue) return '*'

    return length
  }

  currentLength () {
    return window.Folio.wordCount({ text: this.element.value }).charactersWithSpaces
  }

  hasActiveMaxValue () {
    return this.hasMaxValue && !!this.maxValue
  }

  removeElementFromFormGroup () {
    const formGroup = this.element.closest('.form-group')

    const wrap = formGroup.querySelector('.f-input-character-counter-wrap')

    if (!wrap) return
    if (!wrap.parentNode) return
    wrap.parentNode.removeChild(wrap)
  }
})
