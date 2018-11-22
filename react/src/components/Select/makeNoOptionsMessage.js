export default function makeNoOptionsMessage (options) {
  return ({ inputValue }) => {
    if (options.indexOf(inputValue) === -1) {
      return window.FolioConsole.translations.noResults
    } else {
      return window.FolioConsole.translations.used
    }
  }
}
