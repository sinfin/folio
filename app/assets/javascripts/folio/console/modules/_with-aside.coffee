$('.f-c-with-aside__toggle').on 'click', ->
  $(this)
    .closest('.f-c-with-aside')
    .toggleClass('f-c-with-aside--aside-collapsed')
