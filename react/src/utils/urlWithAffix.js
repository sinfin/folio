export default function urlWithAffix (url, affix) {
  if (!affix || affix === '?') return url

  const parts = url.split('?')
  const withAffix = `${parts[0]}${affix}`

  const rest = parts.slice(1).join('?')

  if (rest) {
    const joiner = withAffix.indexOf('?') === -1 ? '?' : '&'
    return `${withAffix}${joiner}${rest}`
  } else {
    return withAffix
  }
}
