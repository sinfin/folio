window.Folio.Stimulus.register('f-c-atoms-word-count', class extends window.Stimulus.Controller {
  static targets = ['wordsCount', 'charactersCount']

  static values = {
    locale: String,
    visible: Boolean,
  }

  connect () {
    this.updateCounts()
  }

  onUpdateAtomPreviews (e) {
    this.updateCounts()
  }

  updateCounts () {
    let text = ""

    const hash = window.Folio.formToHash(this.element.closest('form'))
    const attributesKey = this.localeValue ? `${this.localeValue}_atoms_attributes` : 'atoms_attributes'

    const key = Object.keys(hash).find((key) => hash[key][attributesKey])
    const countableFieldTypes = ['string', 'text', 'richtext']

    if (key) {
      const subHash = hash[key][attributesKey]

      this.structures = this.structures || JSON.parse(document.querySelector('.f-c-atoms').dataset.atoms).structures

      Object.values(subHash).forEach((atomHash) => {
        const structure = this.structures[atomHash.type].structure

        Object.keys(structure).forEach((structureKey) => {
          if (countableFieldTypes.indexOf(structure[structureKey].type) !== -1) {
            if (atomHash[structureKey]) {
              text += atomHash[structureKey]
            }
          }
        })
      })
    }

    const result = window.Folio.wordCount({ text })

    this.wordsCountTarget.innerText = result.formattedWords
    this.charactersCountTarget.innerText = result.formattedCharacters
  }

  onAtomsLocaleSwitch (e) {
    if (e && e.detail && e.detail.locale) {
      this.visibleValue = this.localeValue === e.detail.locale
    }
  }
})
