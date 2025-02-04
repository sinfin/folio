window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.HtmlAutoFormat = window.FolioConsole.HtmlAutoFormat || {}
window.FolioConsole.HtmlAutoFormat.enabled = true

window.FolioConsole.HtmlAutoFormat.CLASS_NAME = 'f-c-html-auto-format'

window.FolioConsole.HtmlAutoFormat.MAPPINGS = {
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

window.FolioConsole.HtmlAutoFormat.redactorBlurCallback = ({ redactor }) => {
  if (!window.FolioConsole.HtmlAutoFormat.enabled) return

  const html = redactor.source.getCode()
  const replaced = window.FolioConsole.HtmlAutoFormat.replace({ html, notify: true })

  if (replaced !== html) {
    redactor.source.setCode(replaced)
  }
}

window.FolioConsole.HtmlAutoFormat.sanity = 0

window.FolioConsole.HtmlAutoFormat.wrapInSpan = ({ string, from, cancelAfter, notify }) => {
  if (!window.FolioConsole.HtmlAutoFormat.span) {
    window.FolioConsole.HtmlAutoFormat.span = document.createElement('span')
    window.FolioConsole.HtmlAutoFormat.span.className = window.FolioConsole.HtmlAutoFormat.CLASS_NAME
    window.FolioConsole.HtmlAutoFormat.span.dataset.controller = window.FolioConsole.HtmlAutoFormat.CLASS_NAME
  }

  if (cancelAfter) {
    window.FolioConsole.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatCancelAfterValue = cancelAfter
  } else {
    delete window.FolioConsole.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatCancelAfterValue
  }

  if (notify) {
    window.FolioConsole.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatNotifyValue = Date.now()
  } else {
    delete window.FolioConsole.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatNotifyValue
  }

  window.FolioConsole.HtmlAutoFormat.span.dataset.fCHtmlAutoFormatFromValue = from
  window.FolioConsole.HtmlAutoFormat.span.innerHTML = string

  return window.FolioConsole.HtmlAutoFormat.span.outerHTML
}

window.FolioConsole.HtmlAutoFormat.useMapping = ({ mapping, textNode, notify }) => {
  let replacedSomething = false
  let html = ''

  if (mapping.to) {
    html = textNode.nodeValue.replace(mapping.from, (match, offset, string) => {
      replacedSomething = true
      return window.FolioConsole.HtmlAutoFormat.wrapInSpan({ string: match.replace(mapping.from, mapping.to), from: mapping.from, cancelAfter: mapping.cancelAfter, notify })
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
          html += window.FolioConsole.HtmlAutoFormat.wrapInSpan({ string: mapping.transform[groupKey], from: mapping.from, cancelAfter: mapping.cancelAfter, notify })
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

window.FolioConsole.HtmlAutoFormat.replaceInNode = ({ locale, node, notify }) => {
  let replaced = false

  window.FolioConsole.HtmlAutoFormat.MAPPINGS.commons.forEach((mapping) => {
    if (replaced) return

    if (window.FolioConsole.HtmlAutoFormat.useMapping({ mapping, textNode: node, notify })) {
      replaced = true
    }
  })

  if (replaced) return true

  if (window.FolioConsole.HtmlAutoFormat.MAPPINGS[locale]) {
    window.FolioConsole.HtmlAutoFormat.MAPPINGS[locale].forEach((mapping) => {
      if (replaced) return

      if (window.FolioConsole.HtmlAutoFormat.useMapping({ mapping, textNode: node, notify })) {
        replaced = true
      }
    })
  }

  return replaced
}

window.FolioConsole.HtmlAutoFormat.loopNode = ({ node, locale, notify }) => {
  window.FolioConsole.HtmlAutoFormat.sanity -= 1
  if (window.FolioConsole.HtmlAutoFormat.sanity < 0) return

  if (node.tagName) {
    if (node.tagName === 'SPAN' && node.className === window.FolioConsole.HtmlAutoFormat.CLASS_NAME) {
      return false
    } else {
      let shouldReloop = false

      for (const child of node.childNodes) {
        if (window.FolioConsole.HtmlAutoFormat.loopNode({ node: child, locale, notify })) {
          // if replacement is performed, reloop!
          shouldReloop = true
          break
        }
      }

      if (shouldReloop) {
        return window.FolioConsole.HtmlAutoFormat.loopNode({ node, locale, notify })
      }
    }

    return false
  } else {
    return window.FolioConsole.HtmlAutoFormat.replaceInNode({ node, locale, notify })
  }
}

window.FolioConsole.HtmlAutoFormat.replace = (opts) => {
  const locale = opts.locale || document.documentElement.lang

  const div = document.createElement('div')
  div.innerHTML = opts.html

  window.FolioConsole.HtmlAutoFormat.sanity = 100000
  window.FolioConsole.HtmlAutoFormat.loopNode({ node: div, locale, notify: opts.notify })

  return div.innerHTML
}

window.Folio.Stimulus.register('f-c-html-auto-format', class extends window.Stimulus.Controller {
  static values = {
    cancelAfter: { type: String, default: '' },
    from: { type: String, default: '' },
    cancelled: { type: Boolean, default: false },
    notify: { type: Number, default: 0 },
  }

  connect () {
    this.element.dataset.action = 'click->f-c-html-auto-format#cancel'
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

  cancel (e) {
    e.preventDefault()
    e.stopPropagation()
    console.log('cancel!', this.element)
  }
})
