$ ->
  $cols = $('.f-c-merges-form-row__col')
  return if $cols.length is 0

  $cols.on 'click', ->
    $col = $(this)
    $col.find('.f-c-merges-form-row__radio').prop('checked', true)
    # $group = $col.find('.form-group')
    # $group.removeClass('disabled')
    # $group.find('.disabled').removeClass('disabled')
    # $group.find('.form-control').prop('disabled', false)

    # $sibling = $col.siblings('.f-c-merges-form-row__col')
    # $siblingGroup = $sibling.find('.form-group')
    # $siblingGroup.addClass('disabled')
    # $siblingGroup.find('label, .form-control').addClass('disabled')
    # $siblingGroup.find('.form-control').prop('disabled', true)
