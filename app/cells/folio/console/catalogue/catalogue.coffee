$ ->
  $catalogues = $('.f-c-catalogue--collection-actions')
  return if $catalogues.length is 0

  onCheckboxChange = ($catalogue) ->
    ids = []

    $catalogue.find('.f-c-catalogue__collection-actions-checkbox:checked').each ->
      ids.push(@value)

    $bar = $catalogue.find('.f-c-catalogue__collection-actions-bar')

    $bar.data('ids', ids.join(','))

    $bar
      .prop('hidden', ids.length is 0)
      .find('.f-c-catalogue__collection-actions-bar-count')
      .text(ids.length)

    $bar
      .find("[data-url-base]")
      .each ->
        $this = $(this)
        $this.prop('href', "#{$this.data('url-base')}?ids=#{ids}")

  $(document)
    .on 'change', '.f-c-catalogue__collection-actions-checkbox', ->
      onCheckboxChange($(this).closest('.f-c-catalogue'))

    .on 'click', '.f-c-catalogue__collection-actions-bar-close', ->
      $catalogue = $(this).closest('.f-c-catalogue')
      $catalogue.find('.f-c-catalogue__collection-actions-checkbox').prop('checked', false)
      onCheckboxChange($catalogue)

    .on 'submit', '.f-c-catalogue__collection-actions-bar-form', (e) ->
      $form = $(this)
      $bar = $form.closest('.f-c-catalogue__collection-actions-bar')
      ids = $bar.data('ids')

      if ids
        $form.find('.f-c-catalogue__collection-actions-bar-input').remove()
        $form.append """
          <input type="hidden" class="f-c-catalogue__collection-actions-bar-input" name="ids" value="#{ids}">
        """
      else
        e.preventDefault()
