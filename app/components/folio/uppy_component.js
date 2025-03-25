//= require folio/remote_scripts

window.Folio.Stimulus.register('f-uppy', class extends window.Stimulus.Controller {
  static values = {
    fileType: String,
    inline: Boolean,
    maxNumberOfFiles: Number,
    existingId: String
  }

  static targets = ['trigger', 'loader']

  connect () {
    window.folioUppyCounter = (window.folioUppyCounter || 0) + 1
    this.folioUppyCounter = window.folioUppyCounter

    this.element.classList.add(`f-uppy--${window.folioUppyCounter}`)
    this.triggerTarget.classList.add(`f-uppy__trigger--${window.folioUppyCounter}`)

    window.Folio.RemoteScripts.run({
      key: 'uppy-js',
      urls: ['https://unpkg.com/uppy@4.13.3/dist/uppy.min.js'],
      cssUrls: ['https://unpkg.com/uppy@4.13.3/dist/uppy.min.css']
    }, () => {
      this.addCsLocale()
      this.init()
    })
  }

  disconnect () {
    if (!this.uppy) return

    this.uppy.destroy()
    delete this.uppy
  }

  init () {
    if (this.uppy) return

    const opts = {}

    if (this.maxNumberOfFilesValue) {
      opts.restrictions = {
        maxNumberOfFiles: this.maxNumberOfFilesValue
      }
    }

    this.uppy = new window.Uppy.Uppy(opts)

    const dashboardOpts = {
      inline: this.inlineValue,
      locale: document.documentElement.lang === 'cs' ? window.Uppy.locales.cs_CZ : null
    }

    if (this.inlineValue) {
      dashboardOpts.target = this.element
    } else {
      dashboardOpts.target = document.body
      dashboardOpts.trigger = `.f-uppy__trigger--${this.folioUppyCounter}`
    }

    this.uppy.use(window.Uppy.Dashboard, dashboardOpts)

    this.uppy.use(window.Uppy.DropTarget, {
      target: document.body
    })

    const args = { type: this.fileTypeValue }
    if (this.existingIdValue) args.existing_id = this.existingIdValue

    this.uppy.use(window.Uppy.AwsS3, {
      getUploadParameters (file) {
        return window.Folio.Api.apiPost('/folio/api/s3/before', { ...args, file_name: file.name }).then((response) => {
          return {
            method: 'PUT',
            url: response.s3_url
          }
        })
      }
    })

    this.uppy.on('upload-success', (file, result) => {
      this.uppyUploadSuccess(file, result)
    })

    this.uppy.on('complete', (result) => {
      this.uppyComplete(result)
    })

    if (!this.inlineValue) {
      this.uppy.on('files-added', (_files) => {
        this.uppy.getPlugin('Dashboard').openModal()
      })
    }

    this.loaderTarget.remove()
  }

  uppyComplete (_result) {
    if (!this.inlineValue) {
      this.uppy.getPlugin('Dashboard').closeModal()
    }
  }

  uppyUploadSuccess (file, result) {
    this.dispatch('upload-success', { detail: { file, result } })
  }

  addCsLocale () {
    window.Uppy.locales.cs_CZ = { strings: { addMore: 'P\u0159idat dal\u0161\xED', addMoreFiles: 'P\u0159idat dal\u0161\xED soubory', addingMoreFiles: 'P\u0159id\xE1v\xE1n\xED dal\u0161\xEDch soubor\u016F', allowAccessDescription: 'Pokud chcete po\u0159izovat fotografie va\u0161\xEDm za\u0159\xEDzen\xEDm, povolte pros\xEDm p\u0159\xEDstup ke kame\u0159e.', allowAccessTitle: 'Povolte pros\xEDm p\u0159\xEDstup ke kame\u0159e.', authenticateWith: 'P\u0159ipojit k %{pluginName}', authenticateWithTitle: 'Pros\xEDm p\u0159ihlaste se k %{pluginName} pro v\xFDb\u011Br soubor\u016F', back: 'Zp\u011Bt', browse: 'proch\xE1zet', browseFiles: 'proch\xE1zet', cancel: 'Zru\u0161it', cancelUpload: 'Zru\u0161it nahr\xE1v\xE1n\xED', chooseFiles: 'Vyberte soubory', closeModal: 'Zav\u0159\xEDt dialog', companionError: 'Spojen\xED s modulem Companion se nezda\u0159ilo', complete: 'Hotovo', connectedToInternet: 'P\u0159ipojeno k internetu', copyLink: 'Zkop\xEDrovat odkaz', copyLinkToClipboardFallback: 'Zkop\xEDrujte odkaz n\xED\u017Ee', copyLinkToClipboardSuccess: 'Odkaz zkop\xEDrov\xE1n do schr\xE1nky', creatingAssembly: 'Nahr\xE1v\xE1n\xED se p\u0159ipravuje...', creatingAssemblyFailed: 'Transloadit: Nelze vytvo\u0159it Assembly', dashboardTitle: 'Nahr\xE1t soubory', dashboardWindowTitle: 'Okno pro nahr\xE1n\xED soubor\u016F. (Stiskn\u011Bte ESC pro zav\u0159en\xED.)', dataUploadedOfTotal: '%{complete} z %{total}', done: 'Dokon\u010Deno', dropHereOr: 'P\u0159et\xE1hn\u011Bte soubory sem nebo %{browse}', dropHint: 'P\u0159et\xE1hn\u011Bte soubory sem', dropPasteBoth: 'P\u0159et\xE1hn\u011Bte soubory sem, vlo\u017Ete je, nebo %{browse}', dropPasteFiles: 'P\u0159et\xE1hn\u011Bte soubory sem, vlo\u017Ete je, nebo %{browse}', dropPasteFolders: 'P\u0159et\xE1hn\u011Bte soubory sem, vlo\u017Ete je, nebo %{browse}', dropPasteImportBoth: 'P\u0159et\xE1hn\u011Bte soubory sem, vlo\u017Ete je, %{browse} nebo je importujte', dropPasteImportFiles: 'P\u0159et\xE1hn\u011Bte soubory sem, vlo\u017Ete je, %{browse} nebo je importujte', dropPasteImportFolders: 'P\u0159et\xE1hn\u011Bte soubory sem, vlo\u017Ete je, %{browse} nebo je importujte', editFile: 'Upravit soubor', editing: 'Upravujete %{file}', emptyFolderAdded: 'Nebyly p\u0159id\xE1ny \u017E\xE1dn\xE9 soubory, adres\xE1\u0159 je pr\xE1zdn\xFD.', encoding: 'P\u0159ev\xE1d\u011Bn\xED...', enterCorrectUrl: 'Chybn\xE1 URL: Ujist\u011Bte se, \u017Ee vkl\xE1d\xE1te p\u0159\xEDm\xFD odkaz na soubor.', enterUrlToImport: 'Vlo\u017Ete URL pro import souboru.', exceedsSize: 'Tento soubor p\u0159ekra\u010Duje maxim\xE1ln\xED povolenou velikost: %{size}', failedToFetch: 'Modulu Companion se nepoda\u0159ilo st\xE1hnout soubor z t\xE9to URL, zkontrolujte pros\xEDm, jestli je URL spr\xE1vn\xE1.', failedToUpload: 'Nepoda\u0159ilo se nahr\xE1t soubor %{file}', fileSource: 'Zdroj souboru: %{name}', filesUploadedOfTotal: { 0: '%{complete} z %{smart_count} souboru nahr\xE1no', 1: '%{complete} z %{smart_count} soubor\u016F nahr\xE1no', 2: '%{complete} z %{smart_count} soubor\u016F nahr\xE1no' }, filter: 'Filtrovat', finishEditingFile: 'Dokon\u010Dit editaci souboru', folderAdded: { 0: 'P\u0159id\xE1n %{smart_count} soubor z adres\xE1\u0159e %{folder}', 1: 'P\u0159id\xE1ny %{smart_count} soubory z adres\xE1\u0159e %{folder}', 2: 'P\u0159id\xE1no %{smart_count} soubor\u016F z adres\xE1\u0159e %{folder}' }, generatingThumbnails: 'Vytv\xE1\u0159\xED se miniatury...', import: 'Importovat', importFrom: 'Importovat z %{name}', loading: 'Nahr\xE1v\xE1n\xED...', logOut: 'Odhl\xE1sit', myDevice: 'Moje za\u0159\xEDzen\xED', noFilesFound: 'Nenalezeny \u017E\xE1dn\xE9 soubory ani adres\xE1\u0159e', noInternetConnection: 'Nep\u0159ipojeno k internetu', openFolderNamed: 'Otev\u0159\xEDt adres\xE1\u0159 %{name}', pause: 'Pozastavit', pauseUpload: 'Pozastavit nahr\xE1v\xE1n\xED', paused: 'Pozastaveno', poweredBy: 'Vytvo\u0159eno pomoc\xED %{uppy}', processingXFiles: { 0: 'Zpracov\xE1n\xED %{smart_count} souboru', 1: 'Zpracov\xE1n\xED %{smart_count} soubor\u016F', 2: 'Zpracov\xE1n\xED %{smart_count} soubor\u016F' }, removeFile: 'Odebrat soubor', resetFilter: 'Reset filtru', resume: 'Pok\u0159a\u010Dovat', resumeUpload: 'Pokra\u010Dovat v nahr\xE1v\xE1n\xED', retry: 'Opakovat', retryUpload: 'Opakovat nahr\xE1v\xE1n\xED', saveChanges: 'Ulo\u017Eit zm\u011Bny', selectFileNamed: 'Vybrat soubor %{name}', selectX: { 0: 'Vybrat %{smart_count}', 1: 'Vybrat %{smart_count}', 2: 'Vybrat %{smart_count}' }, smile: '\xDAsm\u011Bv pros\xEDm!', startRecording: 'Spustit nahr\xE1v\xE1n\xED videa', stopRecording: 'Zastavit nahr\xE1v\xE1n\xED videa', takePicture: 'Po\u0159\xEDdit fotografii', timedOut: 'Stav nahr\xE1v\xE1n\xED se nezm\u011Bnil %{seconds} sekund, nahr\xE1v\xE1n\xED se ukon\u010Duje.', unselectFileNamed: 'Zru\u0161it v\xFDb\u011Br souboru %{name}', upload: 'Nahr\xE1t', uploadComplete: 'Nahr\xE1n\xED dokon\u010Deno', uploadFailed: 'Nahr\xE1n\xED se nezda\u0159ilo', uploadPaused: 'Nahr\xE1n\xED dokon\u010Deno', uploadXFiles: { 0: 'Nahr\xE1t %{smart_count} soubor', 1: 'Nahr\xE1t %{smart_count} soubory', 2: 'Nahr\xE1t %{smart_count} soubor\u016F' }, uploadXNewFiles: { 0: 'Nahr\xE1t +%{smart_count} soubor', 1: 'Nahr\xE1t +%{smart_count} soubory', 2: 'Nahr\xE1t +%{smart_count} soubor\u016F' }, uploading: 'Nahr\xE1v\xE1n\xED', uploadingXFiles: { 0: 'Nahr\xE1v\xE1n\xED %{smart_count} souboru', 1: 'Nahr\xE1v\xE1n\xED %{smart_count} soubor\u016F', 2: 'Nahr\xE1v\xE1n\xED %{smart_count} soubor\u016F' }, xFilesSelected: { 0: '%{smart_count} soubor vybr\xE1n', 1: '%{smart_count} soubory vybr\xE1ny', 2: '%{smart_count} soubor\u016F vybr\xE1no' }, xMoreFilesAdded: { 0: '%{smart_count} dal\u0161\xED soubor p\u0159id\xE1n', 1: '%{smart_count} dal\u0161\xED soubory p\u0159id\xE1ny', 2: '%{smart_count} dal\u0161\xEDch soubor\u016F p\u0159id\xE1no' }, xTimeLeft: '%{time} zb\xFDv\xE1', youCanOnlyUploadFileTypes: 'Lze nahr\xE1t pouze n\xE1sleduj\xEDc\xED typy soubor\u016F: %{types}', youCanOnlyUploadX: { 0: 'Lze nahr\xE1t pouze %{smart_count} soubor', 1: 'Lze nahr\xE1t pouze %{smart_count} soubory', 2: 'Lze nahr\xE1t pouze %{smart_count} soubor\u016F' }, youHaveToAtLeastSelectX: { 0: 'Je t\u0159eba vybrat alespo\u0148 %{smart_count} soubor', 1: 'Je t\u0159eba vybrat alespo\u0148 %{smart_count} soubory', 2: 'Je t\u0159eba vybrat alespo\u0148 %{smart_count} soubor\u016F' } } }
  }
})
