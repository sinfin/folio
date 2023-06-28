window.Folio = window.Folio || {}

window.Folio.Chart = {}

window.Folio.Chart.CDN_URL = "https://cdn.jsdelivr.net/npm/chart.js"

window.Folio.Chart.innerBind = (el) => {
  el.innerHTML = ""

  const canvas = document.createElement('canvas')
  canvas.style.width = "100%"
  canvas.style.height = "100%"
  canvas.className = 'f-chart__canvas'
  el.appendChild(canvas)

  console.log(JSON.parse(el.dataset.chart))
  el.folioChart = new Chart(canvas, JSON.parse(el.dataset.chart))
}

window.Folio.Chart.bind = (el) => {
  el.dataset.waitingForJavascript = true

  window.Folio.RemoteJs.runWhenLoaded(window.Folio.Chart.CDN_URL, () => {
    if (!el.dataset.waitingForJavascript) return
    delete el.dataset.waitingForJavascript
    window.Folio.Chart.innerBind(el)
  }, () => {
    el.innerText = el.dataset.error
    el.classList.add('f-chart--error')
  })
}

window.Folio.Chart.unbind = (el) => {
  if (el.dataset.waitingForJavascript) {
    delete el.dataset.waitingForJavascript
  }

  if (el.folioChart) {
    el.folioChart.destroy()
    el.folioChart = null
  }

  const canvas = el.querySelector('canvas')

  if (canvas) {
    el.removeChild(canvas)
  }
}

window.Folio.Stimulus.register('f-chart', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Chart.bind(this.element)
  }

  disconnect () {
    window.Folio.Chart.unbind(this.element)
  }
})
