export default function makeNoOptionsMessage (options) {
  return ({ inputValue }) => {
    if (!options || options === true || options.indexOf(inputValue) === -1) {
      return window.FolioConsole.translations.noResults
    } else {
      return window.FolioConsole.translations.used
    }
  }
}
