$ ->
  $('.f-c-users-invite-and-copy__button').on 'click', (e) ->
    e.preventDefault()

    $this = $(this)

    $.ajax
      method: "POST"
      url: $this.data('url')
      success: (res) ->
        if res && res.data
          $res = $(res.data)
          $this.closest('.f-c-users-invite-and-copy').replaceWith($res)
          $res.find('.f-c-users-invite-and-copy__input').focus().select()
          window.bindFolioConsoleClipboardCopyIn($res)
        else
          alert($this.data('failure'))
      failure: ->
        alert($this.data('failure'))
