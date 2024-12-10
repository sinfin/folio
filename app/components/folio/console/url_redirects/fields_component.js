window.Folio.Stimulus.register('f-c-url-redirects-fields', class extends window.Stimulus.Controller {
  static targets = ['demo', 'demoCases', 'demoUnpublished', 'demoInvalid', 'demoLoader']

  connect () {
    this.updateDemo()
  }

  inputBlurred (e) {
    const input = e.target

    if (!input.value) return

    let url

    try {
      const urlObject = new URL(input.value)
      url = urlObject.pathname
      if (urlObject.search) url += urlObject.search
    } catch {
      url = input.value.indexOf('/') === 0 ? input.value : `/${input.value}`
    }

    input.value = url
  }

  inputChanged () {
    this.updateDemo()
  }

  updateDemo () {
    const data = window.Folio.formToHash(this.element.closest('form')).url_redirect

    this.demoLoaderTarget.hidden = true

    if (data.published === '0') {
      this.demoUnpublishedTarget.hidden = true
      this.demoInvalidTarget.hidden = true
      this.demoCasesTarget.hidden = true
    } else if (!data.url_from || !data.url_to || (data.url_from === data.url_to)) {
      this.demoUnpublishedTarget.hidden = true
      this.demoInvalidTarget.hidden = false
      this.demoCasesTarget.hidden = true
    } else {
      if (this.createDemoCasesHtml(data)) {
        this.demoUnpublishedTarget.hidden = true
        this.demoInvalidTarget.hidden = true
        this.demoCasesTarget.hidden = false
      } else {
        this.demoUnpublishedTarget.hidden = true
        this.demoInvalidTarget.hidden = false
        this.demoCasesTarget.hidden = true
      }
    }
  }

  createDemoCasesHtml (data) {
    const consoleUrl = new URL(window.location.href)
    const origin = consoleUrl.origin
    const query = { [`a${Math.random().toString(36).substr(2, 7)}`]: [`a${Math.random().toString(36).substr(2, 7)}`] }
    let formUrlFrom, formUrlTo

    try {
      formUrlFrom = new URL(`${origin}${data.url_from}`)
      formUrlTo = new URL(data.url_to.indexOf("/") === 0 ? `${origin}${data.url_to}` : data.url_to)
    } catch {
      return false
    }

    const variants = [
      [new URL(formUrlFrom.toString()), null],
      [new URL(formUrlFrom.toString()), query],
    ]

    if (formUrlFrom.href.indexOf("?") !== -1) {
      const urlFromWithoutQuery = formUrlFrom.toString().split("?")[0]

      variants.push([new URL(urlFromWithoutQuery), null])
      variants.push([new URL(urlFromWithoutQuery), query])
    }

    const cases = variants.map((variant) => {
      const variantUrl = variant[0]
      const variantQuery = variant[1]
      const urlSearchParams = variantUrl.searchParams

      if (variantQuery) {
        Object.keys(variantQuery).forEach((key) => {
          urlSearchParams.set(key, variantQuery[key])
        })
      }

      let to = null

      if (data.match_query === '1') {
        if (variantUrl.toString() == formUrlFrom.toString()) {
          to = formUrlTo.toString()
        }
      } else {
        if (variantUrl.toString().split("?")[0] == formUrlFrom.toString().split("?")[0]) {
          to = formUrlTo.toString()
        }
      }

      if (to && data.pass_query === '1') {
        const toUrl = new URL(to)

        formUrlFrom.searchParams.forEach((value, key) => {
          toUrl.searchParams.set(key, value)
        })

        variantUrl.searchParams.forEach((value, key) => {
          toUrl.searchParams.set(key, value)
        })

        to = toUrl.toString()
      }

      return { from: variantUrl.toString(), to }
    })

    let html = ""

    const arrowHtml = window.Folio.Ui.Icon.create("subdirectory_arrow_right").outerHTML
    const checkHtml = window.Folio.Ui.Icon.create("check").outerHTML
    const closeHtml = window.Folio.Ui.Icon.create("close").outerHTML

    cases.forEach(({ from, to }) => {
      html += `
        <div class="f-c-url-redirects-fields__demo-case f-c-url-redirects-fields__demo-case--to-${to ? "present" : "blank"} border-top pt-3 mt-3">
          <a class="f-c-url-redirects-fields__demo-case-from" href="${from}" target="_blank">
            ${from}
          </a>

          <div class="f-c-url-redirects-fields__demo-case-arrow-wrap">
            ${arrowHtml}
          </div>

          <div class="f-c-url-redirects-fields__demo-case-to-icon">
            ${to ? checkHtml : closeHtml}
          </div>

          ${to ? `
            <div class="f-c-url-redirects-fields__demo-case-to">
              <a href="${to}" target="_blank">${to}</a> (${data.status_code})
            </div>
          ` : ""}
        </div>
      `
    })

    this.demoCasesTarget.innerHTML = html

    return true
  }
})
