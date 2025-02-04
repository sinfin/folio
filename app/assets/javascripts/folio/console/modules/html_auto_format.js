window.Folio = window.Folio || {}
window.Folio.HtmlAutoFormat = window.Folio.HtmlAutoFormat || {}
window.Folio.HtmlAutoFormat.enabled = true

window.Folio.HtmlAutoFormat.CLASS_NAME = 'f-c-html-auto-format'

window.Folio.HtmlAutoFormat.MAPPINGS = {
  commons: [
    { from: '...', to: '…' },
    { from: '->', to: '→' },
    { from: '-&gt;', to: '→' },
    { from: '<-', to: '←' },
    { from: '&lt;-', to: '←' },
    { from: '<=', to: '≤' },
    { from: '&lt;=', to: '≤' },
    { from: '>=', to: '≥' },
    { from: '&gt;=', to: '≥' },
    { from: '!=', to: '≠' },
    { from: '1/2', to: '½' },
    { from: '1/4', to: '¼' },
    { from: '3/4', to: '¾' },
    { from: '^o', to: '°' },
    { from: '(c)', to: '©' },
    { from: '(r)', to: '®' },
    { from: '(tm)', to: '™' },
    { from: /(?<g1c>\s|&nbsp;)(?<g2s>-)(?<g3c>\s|&nbsp;)/, transform: { g2s: '–' }, cancelAfter: '-' }
  ],
  cs: [
    { from: /(?<g1s>")(?<g2c>[^"]+)(?<g3s>")/, transform: { g1s: '„', g3s: '“' }, cancelAfter: '"' },
    { from: /(?<g1s>')(?<g2c>[^']+)(?<g3s>')/, transform: { g1s: '‚', g3s: '‘' }, cancelAfter: "'" },
    { from: /(?<g1s>["“”])(?<g2c>\w)/, transform: { g1s: '„' }, cancelAfter: '"' },
    { from: /(?<g1c>\w)(?<g2s>["“”])/, transform: { g2s: '“' }, cancelAfter: '"' },
    { from: /(?<g1s>['`])(?<g2c>\w)/, transform: { g1s: '‚' }, cancelAfter: "'" },
    { from: /(?<g1c>\w)(?<g2s>['`])/, transform: { g2s: '‘' }, cancelAfter: "'" }
  ]
}

window.Folio.HtmlAutoFormat.redactorBlurCallback = ({ redactor }) => {
  if (!window.Folio.HtmlAutoFormat.enabled) return

  const html = redactor.source.getCode()
  const replaced = window.Folio.HtmlAutoFormat.replace({ html, notify: true })

  if (replaced !== html) {
    redactor.source.setCode(replaced)
  }
}

window.Folio.HtmlAutoFormat.sanity = 0

window.Folio.HtmlAutoFormat.wrapInSpan = ({ string, cancelAfter, notify }) => {
  if (!window.Folio.HtmlAutoFormat.span) {
    window.Folio.HtmlAutoFormat.span = document.createElement('span')
    window.Folio.HtmlAutoFormat.span.className = window.Folio.HtmlAutoFormat.CLASS_NAME
    window.Folio.HtmlAutoFormat.span.dataset.controller = window.Folio.HtmlAutoFormat.CLASS_NAME
  }

  if (cancelAfter) {
    window.Folio.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatCancelAfterValue = cancelAfter
  } else {
    delete window.Folio.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatCancelAfterValue
  }

  if (notify) {
    window.Folio.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatNotifyValue = Date.now()
  } else {
    delete window.Folio.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatNotifyValue
  }

  window.Folio.HtmlAutoFormat.span.innerHTML = string

  return window.Folio.HtmlAutoFormat.span.outerHTML
}

window.Folio.HtmlAutoFormat.useMapping = ({ mapping, textNode, notify }) => {
  let replacedSomething = false
  let html = ''

  if (mapping.to) {
    html = textNode.nodeValue.replace(mapping.from, (match, offset, string) => {
      replacedSomething = true
      return window.Folio.HtmlAutoFormat.wrapInSpan({ string: match.replace(mapping.from, mapping.to), cancelAfter: mapping.cancelAfter, notify })
    })
  } else {
    const match = mapping.from.exec(textNode.nodeValue)

    if (match && match.groups) {
      replacedSomething = true

      const fromIndex = match.index
      const matchLength = match[0].length
      const toIndex = fromIndex + matchLength

      html += match.input.slice(0, fromIndex)

      Object.keys(match.groups).forEach((groupKey) => {
        const string = match.groups[groupKey]

        if (mapping.transform[groupKey]) {
          html += window.Folio.HtmlAutoFormat.wrapInSpan({ string: mapping.transform[groupKey], cancelAfter: mapping.cancelAfter, notify })
        } else {
          html += string
        }
      })

      html += match.input.slice(toIndex)
    }
  }

  if (replacedSomething) {
    const fragment = document.createRange().createContextualFragment(html)
    textNode.replaceWith(fragment)
    return true
  }

  return false
}

window.Folio.HtmlAutoFormat.replaceInNode = ({ locale, node, notify }) => {
  let replaced = false

  window.Folio.HtmlAutoFormat.MAPPINGS.commons.forEach((mapping) => {
    if (replaced) return

    if (window.Folio.HtmlAutoFormat.useMapping({ mapping, textNode: node, notify })) {
      replaced = true
    }
  })

  if (replaced) return true

  if (window.Folio.HtmlAutoFormat.MAPPINGS[locale]) {
    window.Folio.HtmlAutoFormat.MAPPINGS[locale].forEach((mapping) => {
      if (replaced) return

      if (window.Folio.HtmlAutoFormat.useMapping({ mapping, textNode: node, notify })) {
        replaced = true
      }
    })
  }

  return replaced
}

window.Folio.HtmlAutoFormat.loopNode = ({ node, locale, notify }) => {
  window.Folio.HtmlAutoFormat.sanity -= 1
  if (window.Folio.HtmlAutoFormat.sanity < 0) return

  if (node.tagName) {
    if (node.tagName === 'SPAN' && node.className === window.Folio.HtmlAutoFormat.CLASS_NAME) {
      return false
    } else {
      let shouldReloop = false

      for (const child of node.childNodes) {
        if (window.Folio.HtmlAutoFormat.loopNode({ node: child, locale, notify })) {
          // if replacement is performed, reloop!
          shouldReloop = true
          break
        }
      }

      if (shouldReloop) {
        return window.Folio.HtmlAutoFormat.loopNode({ node, locale, notify })
      }
    }

    return false
  } else {
    return window.Folio.HtmlAutoFormat.replaceInNode({ node, locale, notify })
  }
}

window.Folio.HtmlAutoFormat.replace = (opts) => {
  const locale = opts.locale || document.documentElement.lang

  const div = document.createElement('div')
  div.innerHTML = opts.html

  window.Folio.HtmlAutoFormat.sanity = 100000
  window.Folio.HtmlAutoFormat.loopNode({ node: div, locale, notify: opts.notify })

  return div.innerHTML
}

window.Folio.Stimulus.register('f-c-html-auto-format', class extends window.Stimulus.Controller {
  static values = {
    cancelAfter: { type: String, default: '' },
    cancelled: { type: Boolean, default: false },
    notify: { type: Number, default: 0 },
  }

  notifyValueChanged () {
    if (this.notifyValue && this.notifyValue > 0) {
      if ((Date.now() - this.notifyValue) < 1000) {
        this.element.classList.add('f-c-html-auto-format--notify')
      } else {
        this.element.classList.remove('f-c-html-auto-format--notify')
      }
    }
  }
})
