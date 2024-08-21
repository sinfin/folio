window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Phone = {}

window.Folio.Input.Phone.countryNames = {
  cs: { ad: 'Andorra', ae: 'Spojené arabské emiráty', ag: 'Antigua a Barbuda', ai: 'Anguilla', al: 'Albánie', am: 'Arménie', an: 'Nizozemské Antily', ao: 'Angola', aq: 'Antarktida', ar: 'Argentina', as: 'Americká Samoa', at: 'Rakousko', au: 'Austrálie', aw: 'Aruba', az: 'Ázerbajdžán', ba: 'Bosna-Hercegovina', bb: 'Barbados', bd: 'Bangladéš', be: 'Belgie', bf: 'Burkina Faso', bg: 'Bulharsko', bh: 'Bahrajn', bi: 'Burundi', bj: 'Benin', bl: 'Svatý Bartoloměj', bm: 'Bermudy', bn: 'Brunej Darussalam', bo: 'Bolívie', bq: 'Bonaire Svatý Eustach a Saba', br: 'Brazílie', bs: 'Bahamy', bt: 'Bhútánské království', bv: 'Bouvetův ostrov', bw: 'Botswana', by: 'Bělorusko', bz: 'Belize', ca: 'Kanada', cc: 'Kokosové ostrovy', cd: 'Kongo demokratická republika', cf: 'Středoafrická republika', cg: 'Konžská republika', ch: 'Švýcarsko', ci: 'Pobřeží slonoviny', ck: 'Cookovy ostrovy', cl: 'Chile', cm: 'Kamerun', cn: 'ČLR', co: 'Kolumbie', cr: 'Kostarika', cs1: 'Československo', ct: 'Canton a Enderbury', cu: 'Kuba', cv: 'Kapverdy', cw: 'Curaçao', cx: 'Vánoční ostrovy', cy: 'Kypr', cz: 'Česká republika', de: 'Německo', dj: 'Džibutsko', dk: 'Dánsko', dm: 'Dominika', do: 'Dominikánská republika', dz: 'Alžírsko', ec: 'Ekvádor', ee: 'Estonsko', eg: 'Egypt', eh: 'Západní Sahara', er: 'Eritrea', es: 'Španělsko', et: 'Etiopie', fi: 'Finsko', fj: 'Fidži', fk: 'Falklandy', fm: 'Federativní státy a Mikronésie', fo: 'Faerské ostrovy', fr: 'Francie', ga: 'Gabon', gb: 'Velká Británie', gd: 'Grenada', ge: 'Gruzie', gf: 'Francouzská Guayana', gg: 'Guernsey', gh: 'Ghana', gi: 'Gibraltar', gl: 'Grónsko', gm: 'Gambie', gn: 'Guinea', gp: 'Guadeloupe', gq: 'Rovníková Guinea', gr: 'Řecko', gs: 'Jižní Georgie a Jižní Sanwich. o', gt: 'Guatemala', gu: 'Guam', gw: 'Guinea-Bissau', gy: 'Guyana', hk: 'Hongkong', hm: 'Heardův a MacDonaldův o', hn: 'Honduras', hr: 'Chorvatsko', ht: 'Haiti', hu: 'Maďarsko', id: 'Indonésie', ie: 'Irsko', il: 'Izrael', im: 'Ostrov Man', in: 'Indie', io: 'Britské indickooceánské terit', iq: 'Irák', ir: 'Irán', is: 'Island', it: 'Itálie', je: 'Bailiwick Jersey', jm: 'Jamajka', jo: 'Jordánsko', jp: 'Japonsko', jt: 'Johnston I', ke: 'Keňa', kg: 'Kyrgyzstán', kh: 'Kambodža', ki: 'Kiribati', km: 'Komory', kn: 'Sv. Kryštof', kp: 'KLDR', kr: 'Jižní Korea', kw: 'Kuvajt', ky: 'Kajmanské ostrovy', kz: 'Kazachstán', la: 'Laos', lb: 'Libanon', lc: 'Sv. Lucie', li: 'Lichtenštejnsko', lk: 'Srí Lanka', lr: 'Libérie', ls: 'Lesotho', lt: 'Litva', lu: 'Lucembursko', lv: 'Lotyšsko', ly: 'Libye', ma: 'Maroko', mc: 'Monako', md: 'Moldavsko', me: 'Černá Hora', mf: 'Sv. Martin (FR)', mg: 'Madagaskar', mh: 'Marshallovy ostrovy', mi: 'Midwayské ostrovy', mk: 'Makedonie', ml: 'Mali', mm: 'Barma', mn: 'Mongolsko', mo: 'Macao', mp: 'Severní Marianny', mq: 'Martinik', mr: 'Mauritánie', ms: 'Montserrat', mt: 'Malta', mu: 'Mauricius', mv: 'Maledivy', mw: 'Malawi', mx: 'Mexiko', my: 'Malajsie', mz: 'Mosambik', na: 'Namíbie', nc: 'Nová Kaledonie', ne: 'Niger', nf: 'Norfolk', ng: 'Nigérie', ni: 'Nikaragua', nl: 'Nizozemí', no: 'Norsko', np: 'Nepál', nr: 'Nauru', nt: 'Neutrální území', nu: 'Niue', nz: 'Nový Zéland', om: 'Omán', pa: 'Panama', pc: 'Mikronésie', pe: 'Peru', pf: 'Francouzská Polynésie', pg: 'Papua-Nová Guinea', ph: 'Filipíny', pk: 'Pákistán', pl: 'Polsko', pm: 'Saint Pierre a Miquelon', pn: 'Pitcairnovy ostrovy', pr: 'Portoriko', ps: 'Palestina', pt: 'Portugalsko', pw: 'Palau', py: 'Paraguay', pz: 'Panamské průplav. pásmo', qa: 'Katar', re: 'Réunion', ro: 'Rumunsko', rs: 'Srbsko', ru: 'Rusko', rw: 'Rwanda', sa: 'Saúdská Arábie', sb: 'Šalomounovy ostrovy', sc: 'Seychelly', sd: 'Súdán', se: 'Švédsko', sg: 'Singapur', sh: 'Sv. Helena', si: 'Slovinsko', sj: 'Špicberky', sk: 'Slovensko', sl: 'Sierra Leone', sm: 'San Marino', sn: 'Senegal', so: 'Somalsko', sr: 'Surinam', ss: 'Jihosúdánská republika', st: 'Sv. Tomáš', su: 'SSSR', sv: 'Salvador', sx: 'Sv. Martin (NL)', sy: 'Sýrie', sz: 'Svazijsko', tc: 'Turks a Caicos', td: 'Čad', tf: 'Francouzská jižní území', tg: 'Togo', th: 'Thajsko', tj: 'Tádžikistán', tk: 'Tokelau', tl: 'Demokratická republika Východní Timor', tn: 'Tunisko', to: 'Tonga', tp: 'Východní Timor', tr: 'Turecko', tt: 'Trinidad a Tobago', tu: 'Turkmenistán', tv: 'Tuvalu', tw: 'Tchaj-wan', tz: 'Tanzánie', ua: 'Ukrajina', ug: 'Uganda', um: 'Ostrovy USA v Tichém o', us: 'USA', uy: 'Uruguay', uz: 'Uzbekistán', va: 'Vatikán', vc: 'Sv. Vincenc a Grenadiny', ve: 'Venezuela', vg: 'Britské Panenské ostrovy', vi: 'Panenské ostrovy (USA)', vn: 'Vietnam', vu: 'Vanuatu', wf: 'Wallisovy ostrovy', wk: 'Wake I', ws: 'Samoa', yd: 'Jižní Jemen', ye: 'Jemen', yt: 'Mayotte', za: 'Jihoafrická republika', zm: 'Zambie', zr: 'Zair', selectedCountryAriaLabel: 'Vybraná země', noCountrySelected: 'Žádná vybraná země', countryListAriaLabel: 'Seznam zemí', searchPlaceholder: 'Hledat', zeroSearchResults: 'Nenalezeny žádné země', oneSearchResult: 'nalezna 1 země', multipleSearchResults: '${count} zemí' }
}

window.Folio.Input.Phone.intlTelInputOptions = {
  separateDialCode: true,
  autoPlaceholder: 'aggressive'
}

window.Folio.Input.Phone.onAddressCountryCodeChange = (wrap, countryCode) => {
  for (const input of wrap.querySelectorAll(window.Folio.Input.Phone.SELECTOR)) {
    if (!input.value) {
      input.folioInputPhoneIntlTelInput.setCountry(countryCode)
    }
  }
}

window.Folio.Input.Phone.onChangeForInput = (input) => {
  const dialCode = `+${input.folioInputPhoneIntlTelInput.s.dialCode}`

  let value = input.value.replace(/ /g, '')

  if (value.indexOf(dialCode) === 0) {
    value = value.replace(dialCode, '')
  }

  input.folioInputPhoneHiddenInput.value = value ? `${dialCode}${value}` : ''
}

window.Folio.Input.Phone.onChange = (e) => {
  window.Folio.Input.Phone.onChangeForInput(e.target)
}

window.Folio.Input.Phone.copyBootstrapValidationClassNames = (input) => {
  if (input.classList.contains('is-invalid')) {
    input.closest('.iti').classList.add('is-invalid')
  }
}

window.Folio.Input.Phone.bind = (input, options = {}) => {
  window.Folio.RemoteScripts.run('intl-tel-input', () => {
    window.Folio.Input.Phone.innerBind(input, options)
  })
}

window.Folio.Input.Phone.onFormChange = (e) => {
  if (!e || !e.target || e.target.tagName !== 'SELECT') return
  if (e.target.name.indexOf('country_code') === -1) return
  if (!e.target.value) return

  const countryCode = e.target.value.toLowerCase()
  if (!countryCode) return

  const form = e.currentTarget

  for (const input of form.querySelectorAll('.iti__tel-input')) {
    if (!input.value && input.folioInputPhoneIntlTelInput) {
      try {
        input.folioInputPhoneIntlTelInput.setCountry(countryCode)
      } catch {}
    }
  }
}

window.Folio.Input.Phone.innerBind = (input, options = {}) => {
  const hiddenInput = document.createElement('input')
  hiddenInput.type = 'hidden'
  hiddenInput.name = input.name
  hiddenInput.value = input.value

  input.removeAttribute('name')
  input.parentElement.appendChild(hiddenInput)
  input.folioInputPhoneHiddenInput = hiddenInput

  input.addEventListener('input', window.Folio.Input.Phone.onChange)
  input.addEventListener('countrychange', window.Folio.Input.Phone.onChange)

  const fullOpts = Object.assign({}, window.Folio.Input.Phone.intlTelInputOptions, { dropdownContainer: document.body })

  if (window.Folio.Input.Phone.countryNames[document.documentElement.lang]) {
    fullOpts.i18n = window.Folio.Input.Phone.countryNames[document.documentElement.lang]
  }

  if (options.defaultCountryCode) {
    fullOpts.initialCountry = options.defaultCountryCode
  }

  if (document.documentElement.lang === 'cs' || document.documentElement.lang === 'sk') {
    fullOpts.preferredCountries = ['cz', 'sk']
  } else {
    fullOpts.preferredCountries = []
  }

  input.folioInputPhoneIntlTelInput = window.intlTelInput(input, fullOpts)

  const form = input.closest('form')

  if (form) {
    form.boundFolioInputPhone = true
    form.addEventListener('change', window.Folio.Input.Phone.onFormChange)
  }

  window.Folio.Input.Phone.copyBootstrapValidationClassNames(input)
}

window.Folio.Input.Phone.unbind = (input) => {
  const form = input.closest('form')

  if (form && form.boundFolioInputPhone) {
    form.removeEventListener('change', window.Folio.Input.Phone.onFormChange)
  }

  if (input.folioInputPhoneIntlTelInput) {
    input.folioInputPhoneIntlTelInput.destroy()
    input.folioInputPhoneIntlTelInput = null
  }

  if (input.folioInputPhoneHiddenInput) {
    input.name = input.folioInputPhoneHiddenInput.name
    input.value = input.folioInputPhoneHiddenInput.value
    input.folioInputPhoneHiddenInput.parentElement.removeChild(input.folioInputPhoneHiddenInput)
    input.folioInputPhoneHiddenInput = null
  }

  input.removeEventListener('input', window.Folio.Input.Phone.onChange)
  input.removeEventListener('countrychange', window.Folio.Input.Phone.onChange)
}

window.Folio.Stimulus.register('f-input-form-group-phone', class extends window.Stimulus.Controller {
  static values = {
    defaultCountryCode: { type: String, default: '' }
  }

  static targets = ['input']

  connect () {
    window.Folio.Input.Phone.bind(this.inputTarget, { defaultCountryCode: this.defaultCountryCodeValue })
  }

  disconnect () {
    window.Folio.Input.Phone.unbind(this.inputTarget, { defaultCountryCode: this.defaultCountryCodeValue })
  }
})
