window.Folio = window.Folio || {}

window.Folio.formToHash = (form) => {
  const inputs = form.querySelectorAll('input')
  const hash = {}

  for (const input of inputs) {
    const parts = input.name.split('[')

    if (parts.length === 1) {
      hash[input.name] = input.value
    } else {
      const cleanParts = parts.map((part) => part.replace(']', ''))
      let sanity = 100
      let i = 0
      let runner = hash

      while (i <= cleanParts.length - 1 && sanity > 0) {
        if (i === cleanParts.length - 1) {
          runner[cleanParts[i]] = input.value
        } else {
          runner[cleanParts[i]] = runner[cleanParts[i]] || {}
        }

        runner = runner[cleanParts[i]]

        i += 1
        sanity -= 1
      }
    }
  }

  return hash
}
