window.Folio = window.Folio || {}

window.Folio.Mermaid = {}

window.Folio.Mermaid.CDN_URL = 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js'

window.Folio.Mermaid.initialize = () => {
  if (typeof mermaid !== 'undefined') {
    mermaid.initialize({
      startOnLoad: false,
      theme: 'default',
      themeVariables: {
        primaryColor: '#f8f9fa',
        primaryTextColor: '#212529',
        primaryBorderColor: '#dee2e6',
        lineColor: '#868e96',
        secondaryColor: '#e9ecef',
        tertiaryColor: '#fff'
      }
    })
  }
}

window.Folio.Mermaid.innerBind = (el) => {
  // Find all mermaid code blocks and convert them
  el.querySelectorAll('pre code.language-mermaid').forEach(function (codeEl) {
    const graphDefinition = codeEl.textContent
    const pre = codeEl.parentElement
    const div = document.createElement('div')
    div.className = 'mermaid'
    div.textContent = graphDefinition
    pre.parentNode.replaceChild(div, pre)
  })

  // Initialize mermaid for new elements
  if (typeof mermaid !== 'undefined') {
    mermaid.init(undefined, el.querySelectorAll('.mermaid'))
  }
}

window.Folio.Mermaid.bind = (el) => {
  if (!el.dataset.hasMermaid) return

  el.dataset.waitingForJavascript = true

  window.Folio.RemoteScripts.run({ key: 'mermaid', url: window.Folio.Mermaid.CDN_URL }, () => {
    if (!el.dataset.waitingForJavascript) return
    delete el.dataset.waitingForJavascript

    window.Folio.Mermaid.initialize()
    window.Folio.Mermaid.innerBind(el)
  }, () => {
    console.error('Failed to load Mermaid library')
  })
}

window.Folio.Mermaid.unbind = (el) => {
  if (el.dataset.waitingForJavascript) {
    delete el.dataset.waitingForJavascript
  }

  // Clean up mermaid elements
  el.querySelectorAll('.mermaid').forEach(function (mermaidEl) {
    // Mermaid doesn't have a destroy method, but we can clean up the DOM
    mermaidEl.innerHTML = ''
  })
}

window.Folio.Stimulus.register('f-mermaid', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Mermaid.bind(this.element)
  }

  disconnect () {
    window.Folio.Mermaid.unbind(this.element)
  }
})
