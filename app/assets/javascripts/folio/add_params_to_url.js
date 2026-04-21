//= require folio/form_to_hash

window.Folio = window.Folio || {}

/**
 * Nested plain objects and scalar arrays to application/x-www-form-urlencoded
 * (Rails-style: parent[key]=v, key[]=a&key[]=b). Empty object yields ''.
 */
window.Folio.objectToRailsStyleQueryString = (obj) => {
  if (obj === null || obj === undefined) return ''

  const pairs = []

  const walk = (value, prefix) => {
    if (value === undefined) return

    if (value === null) {
      pairs.push(`${encodeURIComponent(prefix)}=`)
      return
    }

    if (typeof value === 'object' && !Array.isArray(value)) {
      const keys = Object.keys(value)
      if (keys.length === 0) return

      keys.forEach((key) => {
        const v = value[key]
        const nextPrefix = prefix ? `${prefix}[${key}]` : key
        walk(v, nextPrefix)
      })
      return
    }

    if (Array.isArray(value)) {
      if (value.length === 0) return

      const arrayPrefix = `${prefix}[]`
      value.forEach((item) => {
        const s = item === null || item === undefined ? '' : String(item)
        pairs.push(`${encodeURIComponent(arrayPrefix)}=${encodeURIComponent(s)}`)
      })
      return
    }

    pairs.push(`${encodeURIComponent(prefix)}=${encodeURIComponent(String(value))}`)
  }

  walk(obj, '')
  return pairs.join('&')
}

const paramsToNestedObject = (searchParams) => {
  const flat = {}

  searchParams.forEach((value, key) => {
    if (Object.prototype.hasOwnProperty.call(flat, key)) {
      const prev = flat[key]
      flat[key] = Array.isArray(prev) ? [...prev, value] : [prev, value]
    } else {
      flat[key] = value
    }
  })

  return window.Folio.formToHash(flat)
}

const deepMergeParams = (base, override) => {
  if (override === undefined) return base
  if (override === null) return null
  if (Array.isArray(override)) return override
  if (typeof override !== 'object') return override

  const baseObj = (base !== null && typeof base === 'object' && !Array.isArray(base)) ? base : {}
  const out = { ...baseObj }

  Object.keys(override).forEach((k) => {
    const ov = override[k]
    if (ov === undefined) return

    const bv = baseObj[k]

    if (ov !== null && typeof ov === 'object' && !Array.isArray(ov)) {
      if (Object.keys(ov).length === 0) {
        out[k] = {}
      } else if (bv !== null && typeof bv === 'object' && !Array.isArray(bv)) {
        out[k] = deepMergeParams(bv, ov)
      } else {
        out[k] = deepMergeParams({}, ov)
      }
    } else {
      out[k] = ov
    }
  })

  return out
}

window.Folio.addParamsToUrl = (urlString, paramsHash) => {
  if (paramsHash == null || typeof paramsHash !== 'object' || Object.keys(paramsHash).length === 0) {
    return urlString
  }

  const url = urlString.indexOf('/') === 0 ? (new URL(urlString, window.location.origin)) : (new URL(urlString))

  const paramsFromUrl = paramsToNestedObject(url.searchParams)
  const mergedParams = deepMergeParams(paramsFromUrl, paramsHash)
  const query = window.Folio.objectToRailsStyleQueryString(mergedParams)

  url.search = query ? `?${query}` : ''

  return url.toString()
}
