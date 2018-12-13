export default function hiddenFieldHtml (prefix, name, value) {
  return `<input type="hidden" name="${prefix}[${name}]" value="${value || ''}" />`
}
