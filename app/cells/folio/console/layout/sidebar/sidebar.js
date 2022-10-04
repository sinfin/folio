$(document)
  .on('click', '.f-c-layout-sidebar__part-title', (e) => {
    e.preventDefault()

    const $group = $(e.currentTarget).closest('.f-c-layout-sidebar__group')

    $group
      .siblings('.f-c-layout-sidebar__group--expanded')
      .addClass('f-c-layout-sidebar__group--collapsed')
      .removeClass('f-c-layout-sidebar__group--expanded')

    if ($group.hasClass('f-c-layout-sidebar__group--expanded')) {
      $group
        .addClass('f-c-layout-sidebar__group--collapsed')
        .removeClass('f-c-layout-sidebar__group--expanded')
    } else {
      $group
        .addClass('f-c-layout-sidebar__group--expanded')
        .removeClass('f-c-layout-sidebar__group--collapsed')
    }
  })
