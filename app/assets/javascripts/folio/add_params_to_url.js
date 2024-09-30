window.Folio = window.Folio || {}

window.Folio.addParamsToUrl = (urlString, paramsHash) => {
  if (!/^https?:\/\//.test(urlString)) {
    urlString = window.location.origin + urlString;
  }
  
  const url = new URL(urlString)

  Object.keys(paramsHash).forEach((key) => {
    url.searchParams.set(key, paramsHash[key])
  })

  return url.toString()
}
