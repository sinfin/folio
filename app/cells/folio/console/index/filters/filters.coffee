window.folioConsoleBindIndexFiltersAutocomplete = ($input, className) ->
  unless className
    className = "f-c-index-filters__autocomplete-input"
    # Don't autosubmit form
    $input.on 'change', (e) -> e.stopPropagation()

  $input
    .addClass("#{className}--bound")
    .autocomplete
      minLength: 0
      select: (e, ui) ->
        setTimeout (-> $input.closest('[data-auto-submit]').submit()), 0
      source: (request, response) ->
        $.ajax
          url: $input.data('url')
          dataType: "json"
          data:
            q: request.term
            controller: $input.data('controller')
          success: (data) ->
            response(data.data.map((el) => String(el)))
    .on 'focus.indexFiltersAutocomplete', ->
      $input.autocomplete('search', $input.val())

window.folioConsoleUnbindIndexFiltersAutocomplete = ($input) ->
  if $input.hasClass('f-c-index-filters__autocomplete-input--bound')
    $input
      .removeClass('f-c-index-filters__autocomplete-input--bound')
      .off('focus.indexFiltersAutocomplete')
      .autocomplete('destroy')

initDaterangepicker = ($input) ->
  opts =
    alwaysShowCalendars: true
    autoApply: true
    autoUpdateInput: false

  if document.documentElement.lang is 'cs'
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
      monthNames: [ 'Leden', 'Únor', 'Březen', 'Duben', 'Květen', 'Červen', 'Červenec', 'Srpen', 'Září', 'Říjen', 'Listopad', 'Prosinec' ],
      firstDay: 1,
    }

    opts.showCustomRangeLabel = true
    opts.ranges = {
      'Dnes': [
         moment(),
         moment()
       ],
      'Včera': [
         moment().subtract(1, 'days'),
         moment().subtract(1, 'days')
       ],
      'Tento týden': [
         moment().startOf('week'),
         moment().endOf('week')
       ],
      'Minulý týden': [
         moment().subtract(1, 'week').startOf('week'),
         moment().subtract(1, 'week').endOf('week'),
       ],
      'Posledních 30 dnů': [
         moment().subtract(29, 'days'),
         moment()
       ],
      'Tento měsíc': [
         moment().startOf('month'),
         moment().endOf('month')
       ],
      'Minulý měsíc': [
         moment().subtract(1, 'month').startOf('month'),
         moment().subtract(1, 'month').endOf('month'),
       ],
      'Tento rok': [
         moment().startOf('year'),
         moment().endOf('year')
       ],
      'Minulý rok': [
         moment().subtract(1, 'year').startOf('year'),
         moment().subtract(1, 'year').endOf('year'),
       ]
    }

  $input.daterangepicker opts
  $input.on 'apply.daterangepicker', (e, picker) ->
    sd = picker.startDate
    ed = picker.endDate
    $input.val("#{sd.format(opts.locale.format)} - #{ed.format(opts.locale.format)}")
    $input.closest('form').submit()

$ ->
  $('.f-c-index-filters__autocomplete-input').each ->
    window.folioConsoleBindIndexFiltersAutocomplete($(this), 'f-c-index-filters__autocomplete-input')

  $('.f-c-index-filters__date-range-input').each ->
    initDaterangepicker($(this))

  $('.f-c-index-filters__reset-input')
    .on 'click', (e) ->
      e.preventDefault()
      $button = $(this)

      $button
        .closest('.input-group')
        .find('.form-control')
        .val("")

      $button.closest('form').submit()

  $('.f-c-index-filters__text-autocomplete-input').each ->
    window.folioConsoleBindIndexFiltersAutocomplete($(this), 'f-c-index-filters__text-autocomplete-input')
