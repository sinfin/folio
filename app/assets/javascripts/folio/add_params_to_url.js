window.Folio = window.Folio || {}

window.Folio.addParamsToUrl = (url, paramsHash) => {
  const parts = url.split('?', 2)

  const params = new URLSearchParams()
  Object.keys(paramsHash).forEach((key) => {
    params.set(key, paramsHash[key])
  })

  if (parts[1]) {
    parts[1] += `&${params.toString()}`
  } else {
    parts[1] = params.toString()
  }

  return `${parts[0]}?${parts[1]}`
}
