class BaseTooltipController extends window.Stimulus.Controller {
  static values = {
    title: String,
    placement: { type: String, default: 'auto' },
    trigger: { type: String, default: 'hover' },
  }

  connect () {
    this.tooltip = new window.bootstrap.Tooltip(this.element, {
      title: this.titleValue,
      placement: this.placementValue,
      trigger: this.triggerValue,
    })
  }

  disconnect () {
    this.tooltip.dispose()
    delete this.tooltip
  }
}
