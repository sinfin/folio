window.Folio = window.Folio || {}

window.Folio.parameterize = (string) => {
  if (typeof string !== 'string') return string

  return string.normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[^\w\d]/g, '-')
    .toLowerCase()
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
