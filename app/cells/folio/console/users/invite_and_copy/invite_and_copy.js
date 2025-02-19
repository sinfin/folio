// converted via https://coffeescript.org/#try
$(function() {
  return $('.f-c-users-invite-and-copy__button').on('click', function(e) {
    var $this;
    e.preventDefault();
    $this = $(this);
    return $.ajax({
      method: "POST",
      url: $this.data('url'),
      success: function(res) {
        var $res;
        if (res && res.data) {
          $res = $(res.data);
          $this.closest('.f-c-users-invite-and-copy').replaceWith($res);
          $res.find('.f-c-users-invite-and-copy__input').focus().select();
          return window.bindFolioConsoleClipboardCopyIn($res);
        } else {
          return alert($this.data('failure'));
        }
      },
      failure: function() {
        return alert($this.data('failure'));
      }
    });
  });
});
