window.Folio = window.Folio || {}

window.Folio.removeParamsFromUrl = (urlString, paramNames) => {
  const url = urlString.indexOf('/') === 0 ? (new URL(urlString, window.location.origin)) : (new URL(urlString))

  if (!url.search) return urlString

  paramNames.forEach((paramName) => {
    url.searchParams.delete(paramName)
  })

  return url.toString()
}
