// Extracted from https://gist.github.com/msssk/b720a8bddf2ba595347820ac387751ce

window.Folio = window.Folio || {}

window.Folio.numberToHumanSize = (bytes) => {
  const thresh = 1000

  if (Math.abs(bytes) < thresh) {
    return `${bytes} B`
  }

  const units = ['kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']

  let u = -1

  do {
    bytes /= thresh
    ++u
  } while (Math.abs(bytes) >= thresh && u < units.length - 1)

  return `${bytes.toFixed(1)} ${units[u]}`
}
