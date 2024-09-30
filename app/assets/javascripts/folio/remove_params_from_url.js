window.Folio = window.Folio || {}

window.Folio.removeParamsFromUrl = (urlString, paramNames) => {
  if (!/^https?:\/\//.test(urlString)) {
    urlString = window.location.origin + urlString;
  }

  const url = new URL(urlString)

  if (!url.search) return urlString

  paramNames.forEach((paramName) => {
    url.searchParams.delete(paramName)
  })

  return url.toString()
}
