// converted via https://coffeescript.org/#try

$(function() {
  var $catalogues, onCheckboxChange;
  $catalogues = $('.f-c-catalogue--collection-actions');
  if ($catalogues.length === 0) {
    return;
  }
  onCheckboxChange = function($catalogue) {
    var $all, $bar, $checked, ids;
    ids = [];
    $all = $catalogue.find('.f-c-catalogue__collection-actions-checkbox');
    $checked = $all.filter(':checked');
    $checked.each(function() {
      return ids.push(this.value);
    });
    $bar = $catalogue.find('.f-c-catalogue__collection-actions-bar');
    $bar.data('ids', ids.join(','));
    $bar.prop('hidden', ids.length === 0).find('.f-c-catalogue__collection-actions-bar-count').text(ids.length);
    $bar.find("[data-url-base]").each(function() {
      var $this;
      $this = $(this);
      return $this.prop('href', `${$this.data('url-base')}?ids=${ids}`);
    });
    return $catalogue.find('.f-c-catalogue__collection-actions-checkbox-all').prop('checked', $all.length === $checked.length);
  };
  return $(document).on('change', '.f-c-catalogue__collection-actions-checkbox', function() {
    return onCheckboxChange($(this).closest('.f-c-catalogue'));
  }).on('change', '.f-c-catalogue__collection-actions-checkbox-all', function() {
    var $catalogue, $this;
    console.log('all');
    $this = $(this);
    $catalogue = $this.closest('.f-c-catalogue');
    $catalogue.find('.f-c-catalogue__collection-actions-checkbox').prop('checked', $this.prop('checked'));
    return onCheckboxChange($catalogue);
  }).on('click', '.f-c-catalogue__collection-actions-bar-close', function() {
    var $catalogue;
    $catalogue = $(this).closest('.f-c-catalogue');
    $catalogue.find('.f-c-catalogue__collection-actions-checkbox').prop('checked', false);
    return onCheckboxChange($catalogue);
  }).on('submit', '.f-c-catalogue__collection-actions-bar-form', function(e) {
    var $bar, $form, ids;
    $form = $(this);
    $bar = $form.closest('.f-c-catalogue__collection-actions-bar');
    ids = $bar.data('ids');
    if (ids) {
      $form.find('.f-c-catalogue__collection-actions-bar-input').remove();
      return $form.append(`<input type="hidden" class="f-c-catalogue__collection-actions-bar-input" name="ids" value="${ids}">`);
    } else {
      return e.preventDefault();
    }
  });
});
