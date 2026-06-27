window.Folio = window.Folio || {}

window.Folio.wordCount = ({ text, words, characters }) => {
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
    const containsHtml = /<[^>]*>?|&\w+;/m.test(text)

    hash.cleanText = text.replace(/<[^>]*>?/gm, ' ').trim().replace(/(\s|&\w+;)+/g, ' ')

    const textWithoutSpaces = hash.cleanText.replace(/ /g, '')

    hash.charactersWithSpaces = containsHtml ? hash.cleanText.length : text.length
    hash.characters = textWithoutSpaces.length
    hash.words = hash.cleanText ? hash.cleanText.split(' ').length : 0
  } else if (typeof words === 'number' && typeof characters === 'number') {
    hash.words = words
    hash.characters = characters
  }

  const formatter = new Intl.NumberFormat('en-US', {
    maximumFractionDigits: 0,
    useGrouping: true
  })

  hash.formattedCharacters = formatter.format(hash.characters).replace(/,/g, ' ')
  hash.formattedCharactersWithSpaces = formatter.format(hash.charactersWithSpaces).replace(/,/g, ' ')
  hash.formattedWords = formatter.format(hash.words).replace(/,/g, ' ')

  return hash
}
