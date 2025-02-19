// converted via https://coffeescript.org/#try
$(document).on('folioConsoleAasmEventModalTrigger', '.f-c-aasm-email-modal', function(e, data) {
  var $checkbox, $form, $modal, $subject, $title;
  $modal = $(this);
  $form = $modal.find('.f-c-aasm-email-modal__form');
  // formData = $form.data('data')
  $title = $form.find('.f-c-aasm-email-modal__title');
  $title.text($title.data('title').replace('{STATE_NAME}', data.targetStateName));
  $checkbox = $('.f-c-aasm-email-modal__checkbox');
  $checkbox.siblings('.form-check-label').text($checkbox.data('label').replace('{EMAIL}', data.email));
  $form.data('trigger', data.trigger);
  ["klass", "aasm_event", "id", "email"].forEach(function(key) {
    return $form.find(`.f-c-aasm-email-modal__hidden--${key}`).val(data[key]);
  });
  $form.find(".f-c-aasm-email-modal__subject").val(data.emailSubject);
  $form.find(".f-c-aasm-email-modal__text").val(data.emailText);
  $modal.modal('show');
  $subject = $modal.find('.f-c-aasm-email-modal__subject');
  if ($subject.val()) {
    return $modal.find('.f-c-aasm-email-modal__text').focus();
  } else {
    return $subject.focus();
  }
}).on('change keyup', '.f-c-aasm-email-modal__form', function(e) {
  var $form, valid;
  $form = $(this);
  if ($form.find('.f-c-aasm-email-modal__checkbox').prop('checked')) {
    valid = !!$form.find('.f-c-aasm-email-modal__text').val();
  } else {
    valid = true;
  }
  return $form.find('.f-c-aasm-email-modal__submit').prop('disabled', !valid);
}).on('submit', '.f-c-aasm-email-modal__form', function(e) {
  var $form, $modal, $trigger;
  e.preventDefault();
  $form = $(this);
  $modal = $form.closest('.f-c-aasm-email-modal');
  $trigger = $form.data('trigger');
  $modal.addClass('f-c-aasm-email-modal--loading');
  return $.ajax({
    url: $form.prop('action'),
    data: $form.serialize(),
    method: 'POST',
    error: function(jxHr) {
      window.FolioConsole.Flash.flashMessageFromApiErrors(JSON.parse(jxHr.responseText));
      return $modal.removeClass('f-c-aasm-email-modal--loading');
    },
    success: function(res) {
      $trigger.closest('.f-c-state').replaceWith(res.data);
      window.FolioConsole.Flash.flashMessageFromMeta(res);
      return $modal.removeClass('f-c-aasm-email-modal--loading').modal('hide');
    },
    complete: function() {
      $form.data('trigger', null);
      return $form[0].reset();
    }
  });
});
