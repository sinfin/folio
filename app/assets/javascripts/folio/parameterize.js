window.Folio = window.Folio || {}

window.Folio.parameterize = (string) => {
  if (!string) return string

  return string.normalize('NFD').replace(/\p{Diacritic}/gu, '').replace(/[^\w\d]/g, '-')
}
