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
    let wordsCount = 0
    let charactersCount = 0

    const hash = window.Folio.formToHash(this.element.closest('form'))
    const attributesKey = this.localeValue ? `${this.localeValue}_atoms_attributes` : 'atoms_attributes'

    const key = Object.keys(hash).find((key) => hash[key][attributesKey])

    if (key) {
      const subHash = hash[key][attributesKey]

      this.structures = this.structures || JSON.parse(document.querySelector('.f-c-atoms').dataset.atoms).structures

      Object.values(subHash).forEach((atomHash) => {
        const structure = this.structures[atomHash.type].structure

        Object.keys(structure).forEach((structureKey) => {
          if (atomHash[structureKey]) {
            let text

            if (structure[structureKey].type === "richtext") {
              text = atomHash[structureKey].replace(/<[^>]*>?/gm, ' ')
            } else if (structure[structureKey].type === "text" || structure[structureKey].type === "string") {
              text = atomHash[structureKey]
            }

            if (text) {
              text = text.trim().replace(/\s+/g, ' ')

              charactersCount += text.length
              wordsCount += text.split(/\s+/).length
            }
          }
        })
      })
    }

    this.wordsCountTarget.innerText = wordsCount
    this.charactersCountTarget.innerText = charactersCount
  }

  onAtomsLocaleSwitch (e) {
    if (e && e.detail && e.detail.locale) {
      this.visibleValue = this.localeValue === e.detail.locale
    }
  }
})
