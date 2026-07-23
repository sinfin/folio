const INPUT_TOO_SHORT_I18N = {
  cs: (minimumInputLength) => `Zadejte alespoň ${minimumInputLength} znaky.`,
  en: (minimumInputLength) => `Type at least ${minimumInputLength} characters.`
}

const inputTooShortMessage = (minimumInputLength) => {
  const lang = document.documentElement.lang
  const i18nKey = lang ? lang.split('-')[0] : 'en'
  const translation = INPUT_TOO_SHORT_I18N[i18nKey] || INPUT_TOO_SHORT_I18N.en

  return translation(minimumInputLength)
}

export default function makeNoOptionsMessage (options, minimumInputLength) {
  return ({ inputValue }) => {
    if (minimumInputLength && inputValue.length > 0 && inputValue.length < minimumInputLength) {
      return inputTooShortMessage(minimumInputLength)
    }

    if (!options || options === true || options.indexOf(inputValue) === -1) {
      return window.FolioConsole.translations.noResults
    } else {
      return window.FolioConsole.translations.used
    }
  }
}
