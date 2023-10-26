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
    this.$responseField = this.$modal.find('.f-c-ai-assistant-modal__response')
    this.$trigger = null

    this.responses = []
    this.generateResponseRequest = null

    $(document).on('click', '.f-c-ai-assistant-modal-trigger', this.onTriggerClick)

    const $form = this.$modal.find('.f-c-ai-assistant-modal__form')
    this.form = new AIAssistantForm($form, this.onFormSubmit)
  }

  open() {
    this.form.updatePromptField()
    this.appendResponses()

    this.$modal.modal('show')
  }

  formatResponse (responseData) {
    const $responseItemBody = $('<div class="f-c-ai-assistant-modal__response-item-body"></div>')

    const response = responseData.choices[0]
    const responseText = document.createTextNode(response.text)

    const $responseMsg = $(`<p class='mb-0'></p>`).html(responseText)
    $responseItemBody.append($responseMsg)

    if (response.status && response.status.length) {
      $responseItemBody.append($(`<p class='mb-0 mt-1 small'>${response.status}</p>`))
    }

    return $('<div class="f-c-ai-assistant-modal__response-item"></div>').html($responseItemBody)
  }

  appendResponses() {
    this.$responseField.children('.f-c-ai-assistant-modal__response-item').remove()

    if (this.responses.length) {
      this.$modal.addClass('f-c-ai-assistant-modal--show-responses')

      const responses = this.responses.map(this.formatResponse)
      const $loader = this.$modal.find('.f-c-ai-assistant-modal__response-loader')

      // Place responses before loader
      $loader.before(responses)
    }

    setTimeout(() => this.scrollToLastResponse(), 0)
  }

  scrollToLastResponse () {
    const $items = this.$responseField.find('.f-c-ai-assistant-modal__response-item')

    if ($items.length) {
      $items[$items.length-1].scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  scrollToLoader () {
    const $loader = this.$responseField.find('.f-c-ai-assistant-modal__response-loader')

    if ($loader.length) {
      $loader[0].scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  onTriggerClick = (e) => {
    e.preventDefault()

    this.$trigger = $(e.currentTarget)

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
    if (!data) {
      return
    }

    this.responses.push(data.response)
    this.$trigger.data('responses', this.responses)

    this.appendResponses()
  }

  onAPIError = (_jxHr) => {
    this.$modal.addClass('f-c-ai-assistant-modal--error')
  }
}

$(document).on('ready', () => {
  if ($('.f-c-ai-assistant-modal').length) {
    new AIAssistantModal()
  }
})
