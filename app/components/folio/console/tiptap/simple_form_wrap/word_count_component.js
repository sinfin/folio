window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap-word-count', class extends window.Stimulus.Controller {
  static targets = ['wordsCount', 'charactersCount']

  updateWordCount (e) {
    if (!e || !e.detail || !e.detail.wordCount) return
    this.updateCounts(e.detail.wordCount)
  }

  updateCounts (wordCount) {
    this.wordsCountTargets.forEach((target) => { target.innerText = wordCount.formattedWords })
    this.charactersCountTargets.forEach((target) => { target.innerText = wordCount.formattedCharacters })
  }
})
