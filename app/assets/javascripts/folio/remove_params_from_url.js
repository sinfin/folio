window.Folio = window.Folio || {}

window.Folio.removeParamsFromUrl = (urlString, paramNames) => {
  const url = new URL(urlString)

  if (!url.search) return urlString

  paramNames.forEach((paramName) => {
    url.searchParams.delete(paramName)
  })

  return url.toString()
}
