const MESSAGE_BUS_EVENT = 'Folio::AiAssistant::GenerateResponseJob'

class AIAssistantForm {
  constructor($form, onFormSubmit) {
    this.$form = $form

    this.$promptField = $form.find('.f-c-ai-assistant-modal__prompt')
    this.$tokenCounter = $form.find('.f-c-ai-assistant-modal__token-counter')
    this.$submitButton = $form.find('.f-c-ai-assistant-modal__submit')

    this.prompt = ''

    this.tokenCountText = this.$tokenCounter.data('text')
    this.tokenCount = 0
    this.tokenCountRequest = null

    this.formDisabled = false
    this.onFormSubmit = onFormSubmit

    $(document).on('submit', '.f-c-ai-assistant-modal__form', this.onSubmit)
    $(document).on('keyup', '.f-c-ai-assistant-modal__prompt', this.onPromptKeyUp)
    $(document).on('change', '.f-c-ai-assistant-modal__prompt', this.onPromptChange)
  }

  updateSubmitButtonState() {
    this.$submitButton.attr('disabled', this.formDisabled)
  }

  setPrompt(prompt) {
    this.prompt = prompt
    this.formDisabled = this.prompt.length === 0
    this.updateSubmitButtonState()
  }

  updatePromptField() {
    this.$promptField.val(this.prompt)
    this.$promptField.trigger('change')
  }

  requestTokenCount() {
    if (this.tokenCountRequest) {
      this.tokenCountRequest.abort()
    }

    this.tokenCountRequest = $.ajax({
      url: this.$form.data('count-tokens-url'),
      data: this.$form.serialize(),
      method: 'POST',
      dataType: 'JSON',
      success: (data) => {
        if (!data) return
        this.$tokenCounter.attr('hidden', data.count <= 0)
        this.$tokenCounter.html(`${this.tokenCountText}: ${data.count}`)
      }
    })
  }

  onPromptKeyUp = () => {
    this.setPrompt(this.$promptField.val())
  }

  onPromptChange = () => {
    this.requestTokenCount()
  }

  onSubmit = (e) => {
    e.preventDefault()
    if (this.formDisabled) return
    this.onFormSubmit(this.$form)
  }
}

class AIAssistantModal {
  constructor() {
    this.$modal = $('.f-c-ai-assistant-modal')
    this.$responseContainer = this.$modal.find('.f-c-ai-assistant-modal__response')
    this.$trigger = null
    this.$mainFormInput = null

    this.responses = []
    this.generateResponseRequest = null

    this.useResponseText = this.$responseContainer.data('use-response-text')

    $(document)
      .on('click', '.f-c-ai-assistant-modal-trigger', this.onTriggerClick)
      .on('click', '.f-c-ai-assistant-modal__response-action-button', this.onResponseActionButtonClick)

    const $form = this.$modal.find('.f-c-ai-assistant-modal__form')
    this.form = new AIAssistantForm($form, this.onFormSubmit)
  }

  open() {
    this.form.updatePromptField()
    this.appendAllResponses()

    this.$modal.modal('show')
  }

  buildResponseActionButton = (value, large = false) => {
    const $button = $('<button type="button"></button>')

    if (large) {
      $button
        .addClass('f-c-ai-assistant-modal__response-action-button')
        .addClass('f-c-ai-assistant-modal__response-action-button--large')
        .html(this.useResponseText)
    } else {
      $button
        .addClass('f-c-ai-assistant-modal__response-action-button')
        .addClass('f-c-ai-assistant-modal__response-action-button--small')
        .attr('title', this.useResponseText)
        .html(value)
    }

    $button[0].dataset['value'] = value

    return $button[0].outerHTML
  }

  insertActionButtons = (json_obj) => {
    const formattedJson = JSON.stringify(json_obj, null, 2)
    const jsonValueRegex = /(?<=: "|\[\n\s*"|,\n\s*")(.*)(?="[,|\]|\n])/g

    return formattedJson.replace(jsonValueRegex, (_, capturedGroup) => {
      return this.buildResponseActionButton(capturedGroup)
    })
  }

  formatResponseHTML(contentParts) {
    let html = ''

    contentParts.forEach((part) => {
      if (part.type === 'json') {
        const jsonWithActionButtons = this.insertActionButtons(part.val)
        html += $(`<pre></pre>`).html(jsonWithActionButtons)[0].outerHTML
      } else {
        let value = document.createTextNode(part.val)

        if (contentParts.length > 1) {
          value = this.buildResponseActionButton(value.wholeText)
        }

        html += $(`<p class='mb-0'></p>`).html(value)[0].outerHTML
      }
    })

    return html
  }

  buildResponseItemEl = (responseData) => {
    const choice = responseData.choices[0]

    const contentParts = choice.content_parts
    const responseHTML = this.formatResponseHTML(contentParts)

    const $responseItemBody = $('<div class="f-c-ai-assistant-modal__response-item-body"></div>')
    $responseItemBody.append(responseHTML)

    if (choice.status && choice.status.length) {
      $responseItemBody.append($(`<p class='mb-0 mt-1 small'>${choice.status}</p>`))
    }

    if (contentParts.length <= 1 && contentParts[0].type === 'text') {
      const content = contentParts[0].val
      const $button = this.buildResponseActionButton(content, true)
      $responseItemBody.append($button)
    }

    return $('<div class="f-c-ai-assistant-modal__response-item"></div>').html($responseItemBody)
  }

  appendResponse = (responseData) => {
    this.$modal.addClass('f-c-ai-assistant-modal--show-responses')

    const $response = this.buildResponseItemEl(responseData)
    const $loader = this.$modal.find('.f-c-ai-assistant-modal__response-loader')

    // Place responses before loader
    $loader.before($response)

  }

  appendAllResponses() {
    this.$responseContainer.children('.f-c-ai-assistant-modal__response-item').remove()

    if (this.responses.length) {
      this.responses.forEach(this.appendResponse)
    }
  }

  scrollToLastResponse () {
    const $items = this.$responseContainer.find('.f-c-ai-assistant-modal__response-item')

    if ($items.length) {
      $items[$items.length-1].scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  scrollToLoader () {
    const $loader = this.$responseContainer.find('.f-c-ai-assistant-modal__response-loader')

    if ($loader.length) {
      $loader[0].scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  onTriggerClick = (e) => {
    e.preventDefault()

    this.$trigger = $(e.currentTarget)
    this.$mainFormInput = this.$trigger.closest('.form-group').find('.f-input--ai-assistant')

    const prompt = this.$trigger.data('prompt')
    this.form.setPrompt(prompt)

    this.responses = this.$trigger.data('responses') || []
    this.$modal.removeClass('f-c-ai-assistant-modal--show-responses')
    this.$modal.removeClass('f-c-ai-assistant-modal--error')

    this.open()
  }

  onFormSubmit = ($form) => {
    if (this.generateResponseRequest) this.generateResponseRequest.abort()

    this.$modal.removeClass('f-c-ai-assistant-modal--error')
    this.$modal.addClass('f-c-ai-assistant-modal--loading')
    this.scrollToLoader()

    this.generateResponseRequest = $.ajax({
      url: $form.attr('action'),
      data: $form.serialize(),
      method: 'POST',
      dataType: 'JSON',
      success: this.onAPISuccess,
      error: this.onAPIError,
      complete: () => {
        this.$modal.removeClass('f-c-ai-assistant-modal--loading')
      }
    })
  }

  onAPISuccess = (data) => {
    if (!data || !data.response) return

    const responseData = data.response
    this.responses.push(responseData)
    this.$trigger.data('responses', this.responses)

    this.appendResponse(responseData)
    setTimeout(() => this.scrollToLastResponse(), 0)
  }

  onAPIError = (jxHr) => {
    const errorMessage = jxHr.responseJSON.error.message
    this.$modal
      .addClass('f-c-ai-assistant-modal--error')
      .find('.f-c-ai-assistant-modal__status-error-detail')
      .html(errorMessage)
  }

  onResponseActionButtonClick = (e) => {
    const $btns = $('.f-c-ai-assistant-modal__response-action-button')
    const $btn = $(e.currentTarget)

    const responseText = $btn.data('value')
    this.$mainFormInput.val(responseText)
    this.$mainFormInput.trigger('change')

    $btns.removeClass('f-c-ai-assistant-modal__response-action-button--selected')
    $btn.addClass('f-c-ai-assistant-modal__response-action-button--selected')
  }
}

$(document).on('ready', () => {
  if ($('.f-c-ai-assistant-modal').length) {
    new AIAssistantModal()
  }
})
