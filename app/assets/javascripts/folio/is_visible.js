window.Folio = window.Folio || {}

window.Folio.isVisible = (element) => (
  element.offsetWidth ||
  element.offsetHeight ||
  element.getClientRects().length !== 0
)
