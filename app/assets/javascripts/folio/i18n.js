window.Folio = window.Folio || {}

window.Folio.i18n = (map, key) => {
  const source = map[document.documentElement.lang] || map.en
  return source[key]
}
