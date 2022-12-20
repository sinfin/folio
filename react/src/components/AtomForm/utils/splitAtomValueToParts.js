function splitRichTextToParts (value) {
  const splitter = document.createElement('div')
  const parts = []

  splitter.innerHTML = value

  for (const child of splitter.children) {
    parts.push(child.outerHTML)
  }

  return parts
}

function splitTextToParts (value) {
  return value.split(/\n/)
}

export default function splitAtomValueToParts ({ value, isRichText }) {
  if (isRichText) {
    return splitRichTextToParts(value)
  } else {
    return splitTextToParts(value)
  }
}
