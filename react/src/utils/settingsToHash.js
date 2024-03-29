import getJsonFromMultiSelectDom from 'utils/getJsonFromMultiSelectDom'
import getJsonFromFilePicker from 'utils/getJsonFromFilePicker'

export default function settingsToHash () {
  const $ = window.jQuery
  const $settings = $('.f-c-js-atoms-placement-setting')
  const hash = {
    loading: false
  }

  if ($settings.length) {
    $settings.each((i, setting) => {
      if (hash.loading) return

      const $setting = $(setting)
      const key = $setting.data('atom-setting')

      if (key) {
        let val

        if ($setting.data('atom-setting-value')) {
          val = $setting.data('atom-setting-value')
        } else if ($setting.attr('data-atom-setting-value-json')) {
          const raw = $setting.attr('data-atom-setting-value-json')
          try {
            val = JSON.parse(raw)
          } catch {
            val = null
          }
        } else if ($setting.hasClass('selectized')) {
          val = $setting[0].selectize.getValue()
        } else if ($setting.hasClass('f-c-file-picker')) {
          val = getJsonFromFilePicker($setting)
        } else if ($setting.hasClass('form-check-input')) {
          val = $setting[0].checked
        } else if ($setting.hasClass('folio-react-wrap')) {
          if ($setting.find('.f-c-file-placement-list').length) {
            val = getJsonFromMultiSelectDom($setting)
            if (val.length === 0) val = null
          } else if ($setting.find('.f-c-file-placement-list__empty').length) {
            val = null
          } else {
            hash.loading = true
            return
          }
        } else {
          val = $setting.val()
        }

        if (val) {
          hash[key] = hash[key] || {}
          hash[key][$setting.data('locale') || null] = val
        }
      }
    })
  }

  return hash
}
