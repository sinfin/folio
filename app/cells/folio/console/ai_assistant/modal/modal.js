const MESSAGE_BUS_EVENT = 'Folio::AiAssistant::GenerateResponseJob'

class AIAssistantModal {
  constructor() {
    this.$modal = $('.f-c-ai-assistant-modal')
    this.$promptField = this.$modal.find('.f-c-ai-assistant-modal__prompt')
    this.$responseField = this.$modal.find('.f-c-ai-assistant-modal__response')
    this.$submitButton = this.$modal.find('.f-c-ai-assistant-modal__submit')

    this.$trigger = null
    this.prompt = ''
    this.responses = []

    this.apiRequest = null
    this.formDisabled = false

    $(document).on('click', '.f-c-ai-assistant-modal-trigger', this.onTriggerClick)
    $(document).on('submit', '.f-c-ai-assistant-modal__form', this.onPromptSubmit)
    $(document).on('keyup', '.f-c-ai-assistant-modal__prompt', this.onPromptKeyUp)
  }

  open() {
    this.$promptField.val(this.prompt)

    this.appendResponses()

    this.$modal.modal('show')
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

  formatResponse(responseData) {
    const $responseItem = $('<div class="f-c-ai-assistant-modal__response-item"></div>')
    const $responseItemBody = $('<div class="f-c-ai-assistant-modal__response-item-body"></div>')

    const response = responseData.choices[0]
    const $responseMsg = $(`<p class='mb-0'></p>`).html(document.createTextNode(response.text))

    $responseItemBody.append($responseMsg)

    if (response.status && response.status.length) {
      $responseItemBody.append($(`<p class='mb-0 mt-1 small'>${response.status}</p>`))
    }

    $responseItem.html($responseItemBody)

    return $responseItem
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

  updateSubmitButtonState() {
    if (this.formDisabled) {
      this.$submitButton.attr('disabled', true)
    } else {
      this.$submitButton.attr('disabled', false)
    }
  }

  setPrompt(prompt) {
    this.prompt = prompt
    this.formDisabled = this.prompt.length === 0
    this.updateSubmitButtonState()
  }

  onTriggerClick = (e) => {
    e.preventDefault()

    this.$trigger = $(e.currentTarget)

    this.$modal.removeClass('f-c-ai-assistant-modal--show-responses')
    this.$modal.removeClass('f-c-ai-assistant-modal--error')

    this.setPrompt(this.$trigger.data('prompt') || "")
    this.responses = this.$trigger.data('responses') || []

    this.open()
  }

  onPromptKeyUp = () => {
    this.setPrompt(this.$promptField.val())
  }

  onPromptSubmit = (e) => {
    e.preventDefault()

    if (this.formDisabled) return
    if (this.apiRequest) this.apiRequest.abort()

    this.$modal.removeClass('f-c-ai-assistant-modal--error')
    this.$modal.addClass('f-c-ai-assistant-modal--loading')
    this.scrollToLoader()

    const $form = this.$modal.find('.f-c-ai-assistant-modal__form')

    this.apiRequest = $.ajax({
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

  onAPIError = (jxHr) => {
    this.$modal.addClass('f-c-ai-assistant-modal--error')
  }
}

$(document).on('ready', () => {
  if ($('.f-c-ai-assistant-modal').length) {
    new AIAssistantModal()
  }
})
