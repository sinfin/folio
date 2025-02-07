window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.HtmlAutoFormat = window.FolioConsole.HtmlAutoFormat || {}

window.FolioConsole.HtmlAutoFormat.CLASS_NAME = 'f-c-html-auto-format'

window.FolioConsole.HtmlAutoFormat.I18N = {
  cs: {
    tooltip: "Automaticky nahrazeno %{before} <br> Kliknutím zrušíte"
  },
  en: {
    tooltip: "Automatically replaced %{before} <br> Click to cancel"
  }
}

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

window.FolioConsole.HtmlAutoFormat.UNDO_MAPPINGS = {
  '„': '"',
  '“': '"',
  '„': '"',
  '“': '"',
  '‚': "'",
  '‘': "'",
  '‚': "'",
  '‘': "'",
}

window.FolioConsole.HtmlAutoFormat.MAPPINGS.commons.map((mapping) => {
  if (mapping.to) {
    window.FolioConsole.HtmlAutoFormat.UNDO_MAPPINGS[mapping.to] = mapping.from
  }
})

window.FolioConsole.HtmlAutoFormat.redactorBlurCallback = ({ redactor }) => {
  if (!window.FolioConsole.HtmlAutoFormat.enabled) return

  const html = redactor.source.getCode()
  const replaced = window.FolioConsole.HtmlAutoFormat.replace({ html, notify: true })

  if (replaced !== html) {
    redactor.source.setCode(replaced)
  }
}

window.FolioConsole.HtmlAutoFormat.sanity = 0

window.FolioConsole.HtmlAutoFormat.wrapInSpan = ({ string, notify }) => {
  if (!window.FolioConsole.HtmlAutoFormat.span) {
    window.FolioConsole.HtmlAutoFormat.span = document.createElement('span')
    window.FolioConsole.HtmlAutoFormat.span.className = window.FolioConsole.HtmlAutoFormat.CLASS_NAME
    window.FolioConsole.HtmlAutoFormat.span.dataset.controller = window.FolioConsole.HtmlAutoFormat.CLASS_NAME
  }

  if (notify && window.FolioConsole.HtmlAutoFormat.UNDO_MAPPINGS[string]) {
    window.FolioConsole.HtmlAutoFormat.span.classList.add('f-c-html-auto-format--notify')
  } else {
    window.FolioConsole.HtmlAutoFormat.span.classList.remove('f-c-html-auto-format--notify')
  }

  window.FolioConsole.HtmlAutoFormat.span.innerHTML = string

  return window.FolioConsole.HtmlAutoFormat.span.outerHTML
}

window.FolioConsole.HtmlAutoFormat.useMapping = ({ mapping, textNode, notify }) => {
  let replacedSomething = false
  let html = ''

  if (mapping.to) {
    html = textNode.nodeValue.replace(mapping.from, (match, offset, string) => {
      replacedSomething = true
      return window.FolioConsole.HtmlAutoFormat.wrapInSpan({ string: match.replace(mapping.from, mapping.to), notify })
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
          html += window.FolioConsole.HtmlAutoFormat.wrapInSpan({ string: mapping.transform[groupKey], notify })
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
  if (!window.FolioConsole.HtmlAutoFormat.enabled) return

  window.FolioConsole.HtmlAutoFormat.sanity -= 1
  if (window.FolioConsole.HtmlAutoFormat.sanity < 0) return

  if (node.tagName) {
    if (node.tagName === 'SPAN' && node.classList.contains(window.FolioConsole.HtmlAutoFormat.CLASS_NAME)) {
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
  if (!window.FolioConsole.HtmlAutoFormat.enabled) return

  const locale = opts.locale || document.documentElement.lang

  const div = document.createElement('div')
  div.innerHTML = opts.html

  window.FolioConsole.HtmlAutoFormat.sanity = 100000
  window.FolioConsole.HtmlAutoFormat.loopNode({ node: div, locale, notify: opts.notify })

  return div.innerHTML
}

window.FolioConsole.HtmlAutoFormat.onClick = (element) => {
  if (!element) return
  if (element.classList.contains('f-c-html-auto-format--reverted')) return

  const redactorGroup = element.closest('[data-controller="f-input-redactor"]')
  const revertTo = window.FolioConsole.HtmlAutoFormat.UNDO_MAPPINGS[element.innerText]

  if (revertTo) {
    element.innerHTML = revertTo
    element.classList.add('f-c-html-auto-format--reverted')
    delete element.dataset.controller
  } else {
    element.remove()
  }

  if (redactorGroup) {
    const input = redactorGroup.querySelector('[data-f-input-redactor-target="input"]')

    if (input) {
      window.Folio.Input.Redactor.updateByCurrentHtml(input)
    }
  }
}

window.FolioConsole.HtmlAutoFormat.onMouseenter = (element) => {
  if (!element) return
  if (element.classList.contains('f-c-html-auto-format--reverted')) return
  console.log('show tooltip for element', element)
}

window.FolioConsole.HtmlAutoFormat.onMouseleave = (element) => {
  if (!element) return
  if (element.classList.contains('f-c-html-auto-format--reverted')) return
  console.log('hide tooltip for element', element)
}

window.Folio.Stimulus.register('f-c-html-auto-format', class extends window.Stimulus.Controller {
  connect () {
    if (this.element.classList.contains('f-c-html-auto-format--notify')) {
      this.timeout = window.setTimeout(() => {
        this.element.classList.remove('f-c-html-auto-format--notify')
      }, 1000)
    }

    // do it this way so that we don't clutter the HTML in rich text with stimulus data attributes
    this.onClick = (e) => { window.FolioConsole.HtmlAutoFormat.onClick(this.element) }
    this.element.addEventListener('click', this.onClick)

    this.onMouseenter = (e) => { window.FolioConsole.HtmlAutoFormat.onMouseenter(this.element) }
    this.element.addEventListener('mouseenter', this.onMouseenter)

    this.onMouseleave = (e) => { window.FolioConsole.HtmlAutoFormat.onMouseleave(this.element) }
    this.element.addEventListener('mouseleave', this.onMouseleave)
  }

  disconnect () {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      delete this.timeout
    }

    this.element.removeEventListener('click', this.onClick)
    delete this.onClick

    this.element.removeEventListener('mouseenter', this.onMouseenter)
    delete this.onMouseenter

    this.element.removeEventListener('mouseleave', this.onMouseleave)
    delete this.onMouseleave
  }
})
