window.Folio = window.Folio || {}

window.Folio.wordCount = ({ text }) => {
  const hash = {
    text,
    cleanText: '',
    words: 0,
    characters: 0,
    charactersWithSpaces: 0,
    formattedWords: 0,
    formattedCharacters: 0,
    formattedCharactersWithSpaces: 0
  }

  if (text) {
    hash.cleanText = text.replace(/<[^>]*>?/gm, ' ').trim().replace(/(\s|&\w+;)+/g, ' ')

    const textWithoutSpaces = hash.cleanText.replace(/ /g, '')

    hash.charactersWithSpaces = hash.cleanText.length
    hash.characters = textWithoutSpaces.length
    hash.words = hash.cleanText.split(' ').length

    const formatter = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0, useGrouping: true })

    hash.formattedCharacters = formatter.format(hash.characters).replace(/,/g, ' ')
    hash.formattedCharactersWithSpaces = formatter.format(hash.charactersWithSpaces).replace(/,/g, ' ')
    hash.formattedWords = formatter.format(hash.words).replace(/,/g, ' ')
  }

  return hash
}
