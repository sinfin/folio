//= require folio/i18n

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.DateRange = {}

window.Folio.Input.DateRange.i18n = {
  cs: {
    config: {
      locale: {
        format: 'DD. MM. YYYY',
        separator: ' - ',
        applyLabel: 'Potvrdit',
        cancelLabel: 'Zrušit',
        fromLabel: 'Od',
        toLabel: 'Do',
        customRangeLabel: 'Vlastní',
        weekLabel: 'W',
        daysOfWeek: ['Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So'],
        monthNames: ['Leden', 'Únor', 'Březen', 'Duben', 'Květen', 'Červen', 'Červenec', 'Srpen', 'Září', 'Říjen', 'Listopad', 'Prosinec'],
        firstDay: 1
      },
      showCustomRangeLabel: true,
      ranges: {
        Dnes: [window.moment(), window.moment()],
        Včera: [window.moment().subtract(1, 'days'), window.moment().subtract(1, 'days')],
        'Tento týden': [window.moment().startOf('week'), window.moment().endOf('week')],
        'Minulý týden': [window.moment().subtract(1, 'week').startOf('week'), window.moment().subtract(1, 'week').endOf('week')],
        'Posledních 30 dnů': [window.moment().subtract(29, 'days'), window.moment()],
        'Tento měsíc': [window.moment().startOf('month'), window.moment().endOf('month')],
        'Minulý měsíc': [window.moment().subtract(1, 'month').startOf('month'), window.moment().subtract(1, 'month').endOf('month')],
        'Tento rok': [window.moment().startOf('year'), window.moment().endOf('year')],
        'Minulý rok': [window.moment().subtract(1, 'year').startOf('year'), window.moment().subtract(1, 'year').endOf('year')]
      }
    }
  },
  en: {
    config: {
      locale: {
        format: 'DD. MM. YYYY',
        separator: ' - '
      },
      showCustomRangeLabel: true,
      ranges: {
        Today: [window.moment(), window.moment()],
        Yesterday: [window.moment().subtract(1, 'days'), window.moment().subtract(1, 'days')],
        'This week': [window.moment().startOf('week'), window.moment().endOf('week')],
        'Last week': [window.moment().subtract(1, 'week').startOf('week'), window.moment().subtract(1, 'week').endOf('week')],
        'Last 30 days': [window.moment().subtract(29, 'days'), window.moment()],
        'This month': [window.moment().startOf('month'), window.moment().endOf('month')],
        'Last month': [window.moment().subtract(1, 'month').startOf('month'), window.moment().subtract(1, 'month').endOf('month')],
        'This year': [window.moment().startOf('year'), window.moment().endOf('year')],
        'Last year': [window.moment().subtract(1, 'year').startOf('year'), window.moment().subtract(1, 'year').endOf('year')]
      }
    }
  }
}

window.Folio.Input.DateRange.OPTIONS = {
  alwaysShowCalendars: true,
  autoApply: true,
  autoUpdateInput: false
}

window.Folio.Input.DateRange.bindDatepicker = (el, opts) => {
  const $element = window.jQuery(el)

  el.insertAdjacentElement('afterend',
    window.Folio.Ui.Icon.create('calendar_range', { class: 'f-input-date-range-icon' }))

  $element.daterangepicker({
    ...window.Folio.Input.DateRange.OPTIONS,
    ...window.Folio.i18n(window.Folio.Input.DateRange.i18n, 'config'),
    ...opts
  })

  $element.on('apply.daterangepicker', function (e, picker) {
    const sd = picker.startDate
    const ed = picker.endDate

    $element.val(`${sd.format(picker.locale.format)} - ${ed.format(picker.locale.format)}`)
    el.dispatchEvent(new window.Event('change', { bubbles: true }))
  })
}

window.Folio.Input.DateRange.unbindDatepicker = (el) => {
  const icon = el.parentNode.querySelector('.f-input-date-range-icon')

  if (icon) {
    icon.parentNode.removeChild(icon)
  }

  const picker = window.jQuery(el).data('daterangepicker')
  picker.remove()
}

window.Folio.Stimulus.register('f-input-date-range', class extends window.Stimulus.Controller {
  static values = { maxDate: { type: String, default: '' } }

  connect () {
    window.Folio.Input.DateRange.bindDatepicker(this.element, { maxDate: this.maxDateValue })
  }

  disconnect () {
    window.Folio.Input.DateRange.unbindDatepicker(this.element)
  }
})
