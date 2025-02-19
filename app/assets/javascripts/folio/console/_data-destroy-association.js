// converted via https://coffeescript.org/#try
$(document).on('click', '[data-destroy-association]', function(e) {
  var $fields, $this;
  $this = $(this);
  if (!window.confirm(window.FolioConsole.translations.removePrompt)) {
    return $this.blur();
  }
  $fields = $this.closest('.nested-fields');
  $fields.find('input').filter(function() {
    return this.name.indexOf('[_destroy]') !== -1;
  }).val(1);
  $fields.attr('hidden', true);
  return $this.closest('[data-cocoon-single-nested]').trigger('single-nested-change');
});
