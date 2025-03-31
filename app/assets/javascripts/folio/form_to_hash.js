window.Folio = window.Folio || {}

window.Folio.formToHash = (formOrHash) => {
  if (formOrHash instanceof window.HTMLFormElement) {
    const formData = new FormData(formOrHash)
    const hash = {}

    formData.forEach((value, key) => { hash[key] = value })

    return window.Folio.formToHash(hash)
  }

  const hash = {}

  Object.keys(formOrHash).forEach((key) => {
    const value = formOrHash[key]
    const parts = key.split('[')

    if (parts.length === 1) {
      hash[key] = value
    } else {
      const cleanParts = parts.map((part) => part.replace(']', ''))
      const isArray = cleanParts[cleanParts.length - 1] === ''

      if (isArray) cleanParts.pop()

      let sanity = 100
      let i = 0
      let runner = hash

      while (i <= cleanParts.length - 1 && sanity > 0) {
        if (i === cleanParts.length - 1) {
          if (isArray) {
            if (!runner[cleanParts[i]]) runner[cleanParts[i]] = []

            if (value !== '') {
              runner[cleanParts[i]].push(value)
            }
          } else {
            runner[cleanParts[i]] = value
          }
        } else {
          runner[cleanParts[i]] = runner[cleanParts[i]] || {}
        }

        runner = runner[cleanParts[i]]

        i += 1
        sanity -= 1
      }
    }
  })

  return hash
}
