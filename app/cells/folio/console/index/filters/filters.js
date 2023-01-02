window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Index = window.FolioConsole.Index || {}
window.FolioConsole.Index.Filters = {}

window.FolioConsole.Index.Filters.bindAutocompletes = ($input, className) => {
  if (!className) {
    className = 'f-c-index-filters__autocomplete-input'
    // Don't autosubmit form
    $input.on('change', function (e) {
      return e.stopPropagation()
    })
  }

  $input.addClass(`${className}--bound`).autocomplete({
    minLength: 0,
    select: function (e, ui) {
      return setTimeout(function () {
        return $input.closest('[data-auto-submit]').submit()
      }, 0)
    },
    source: function (request, response) {
      return $.ajax({
        url: $input.data('url'),
        dataType: 'json',
        data: {
          q: request.term,
          controller: $input.data('controller')
        },
        success: function (data) {
          return response(data.data.map((el) => {
            return String(el)
          }))
        }
      })
    }
  }).on('focus.indexFiltersAutocomplete', function () {
    return $input.autocomplete('search', $input.val())
  })
}

window.FolioConsole.Index.Filters.unbindAutocompletes = function ($input) {
  if ($input.hasClass('f-c-index-filters__autocomplete-input--bound')) {
    return $input.removeClass('f-c-index-filters__autocomplete-input--bound').off('focus.indexFiltersAutocomplete').autocomplete('destroy')
  }
}

window.FolioConsole.Index.Filters.initDaterangepicker = ($input) => {
  const opts = {
    alwaysShowCalendars: true,
    autoApply: true,
    autoUpdateInput: false
  }

  if (document.documentElement.lang === 'cs') {
    opts.locale = {
      format: 'DD.MM.YYYY',
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
    }
    opts.showCustomRangeLabel = true
    opts.ranges = {
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

  $input.daterangepicker(opts)

  $input.on('apply.daterangepicker', function (e, picker) {
    const sd = picker.startDate
    const ed = picker.endDate
    $input.val(`${sd.format(opts.locale.format)} - ${ed.format(opts.locale.format)}`)
    $input.closest('form').submit()
  })
}

window.FolioConsole.Index.Filters.bind = () => {
  $('.f-c-index-filters__autocomplete-input').each((i, el) => {
    window.FolioConsole.Index.Filters.bindAutocompletes($(el), 'f-c-index-filters__autocomplete-input')
  })

  $('.f-c-index-filters__date-range-input').each((i, el) => {
    window.FolioConsole.Index.Filters.initDaterangepicker($(el))
  })

  $('.f-c-index-filters__reset-input').on('click', (e) => {
    e.preventDefault()
    const $button = $(e.currentTarget)
    $button.closest('.input-group').find('.form-control').val('')
    $button.closest('form').submit()
  })

  $('.f-c-index-filters__text-autocomplete-input').each((i, el) => {
    window.FolioConsole.Index.Filters.bindAutocompletes($(el), 'f-c-index-filters__text-autocomplete-input')
  })
}

$(window.FolioConsole.Index.Filters.bind)
