window.Folio = window.Folio || {}

window.Folio.addParamsToUrl = (urlString, paramsHash) => {
  const url = new URL(urlString)

  Object.keys(paramsHash).forEach((key) => {
    url.searchParams.set(key, paramsHash[key])
  })

  return url.toString()
}
