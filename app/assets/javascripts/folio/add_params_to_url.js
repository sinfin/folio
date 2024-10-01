window.Folio = window.Folio || {}

window.Folio.addParamsToUrl = (urlString, paramsHash) => {
  const url = urlString.indexOf('/') === 0 ? (new URL(urlString, window.location.origin)) : (new URL(urlString))

  Object.keys(paramsHash).forEach((key) => {
    url.searchParams.set(key, paramsHash[key])
  })

  return url.toString()
}
