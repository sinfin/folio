//= require folio/i18n
//= require folio/remote_scripts

window.Folio.Stimulus.register('f-uppy', class extends window.Stimulus.Controller {
  static values = {
    fileType: String,
    inline: Boolean,
    maxNumberOfFiles: Number,
    existingId: String
  }

  static targets = ['trigger', 'loader']

  static ERROR_MESSAGES = {
    en: {
      failedToLoadScripts: 'Failed to load upload component. Please refresh the page.',
      failedToPrepareUpload: 'Failed to prepare file upload. Please try again.',
      systemError: 'Upload failed due to a system error. Please try again.',
      failedToInitialize: 'Failed to initialize upload component. Please refresh the page.'
    },
    cs: {
      failedToLoadScripts: 'Nepodařilo se načíst komponentu pro nahrávání. Prosím obnovte stránku.',
      failedToPrepareUpload: 'Nepodařilo se připravit nahrávání souboru. Zkuste to prosím znovu.',
      systemError: 'Nahrávání selhalo kvůli systémové chybě. Zkuste to prosím znovu.',
      failedToInitialize: 'Nepodařilo se inicializovat komponentu pro nahrávání. Prosím obnovte stránku.'
    }
  }

  connect () {
    window.folioUppyCounter = (window.folioUppyCounter || 0) + 1
    this.folioUppyCounter = window.folioUppyCounter

    this.element.classList.add(`f-uppy--${window.folioUppyCounter}`)
    this.triggerTarget.classList.add(`f-uppy__trigger--${window.folioUppyCounter}`)

    window.Folio.RemoteScripts.run({
      key: 'uppy-js',
      urls: ['https://releases.transloadit.com/uppy/v5.1.2/uppy.min.js'],
      cssUrls: ['https://releases.transloadit.com/uppy/v5.1.2/uppy.min.css']
    }, () => {
      this.addCsLocale()
      this.init()
    }, (error) => {
      console.error('[Uppy] Failed to load Uppy scripts:', error)
      this.showError(window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToLoadScripts'))
    })
  }

  disconnect () {
    if (!this.uppy) return

    this.uppy.destroy()
    delete this.uppy
  }

  init () {
    if (this.uppy) return

    try {
      const opts = {}

      if (this.maxNumberOfFilesValue) {
        opts.restrictions = {
          maxNumberOfFiles: this.maxNumberOfFilesValue
        }
      }

      if (document.documentElement.lang === 'cs') {
        opts.locale = window.Uppy.locales.cs_CZ
      }

      this.uppy = new window.Uppy.Uppy(opts)

      const dashboardOpts = {
        inline: this.inlineValue
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
        getUploadParameters: (file) => {
          return window.Folio.Api.apiPost('/folio/api/s3/before', { ...args, file_name: file.name })
            .then((response) => {
              file.name = response.file_name
              file.s3_path = response.s3_path
              file.jwt = response.jwt

              return {
                method: 'PUT',
                url: response.s3_url
              }
            })
            .catch((error) => {
              console.error('[Uppy] Failed to get S3 upload parameters:', error)
              throw new Error(window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToPrepareUpload'))
            })
        }
      })

      this.uppy.on('upload-success', (file) => {
        this.uppyUploadSuccess(file)
      })

      this.uppy.on('complete', (result) => {
        this.uppyComplete(result)
      })

      this.uppy.on('error', (error) => {
        console.error('[Uppy] System error:', error)
        this.showError(window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'systemError'))
      })

      if (!this.inlineValue) {
        this.uppy.on('files-added', (_files) => {
          this.uppy.getPlugin('Dashboard').openModal()
        })
      }

      if (this.hasLoaderTarget) {
        this.loaderTarget.remove()
      }
    } catch (error) {
      console.error('[Uppy] Failed to initialize Uppy:', error)
      this.showError(window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToInitialize'))
    }
  }

  uppyComplete (result) {
    // Remove only successfully uploaded files
    result.successful.forEach((file) => {
      this.uppy.removeFile(file.id)
    })

    if (!this.inlineValue && result.failed.length === 0) {
      this.uppy.getPlugin('Dashboard').closeModal()
    }
  }

  uppyUploadSuccess (file) {
    this.dispatch('upload-success', { detail: { file } })
  }

  showError (message) {
    if (this.uppy) {
      this.uppy.info(message, 'error', 5000)
    } else {
      this.element.dispatchEvent(new CustomEvent('folio:flash', {
        bubbles: true,
        detail: {
          flash: {
            content: message,
            variant: 'danger'
          }
        }
      }))
    }

    this.dispatch('upload-error-message', { detail: { message } })
  }

  addCsLocale () {
    if (window.Uppy.locales.cs_CZ) return

    window.Uppy.locales.cs_CZ = {
      pluralize: (n) => {
        if (n === 1) return 0
        if (n > 1 && n < 5) return 1
        return 2
      },
      strings: {
        addBulkFilesFailed: {
          0: 'Nepodařilo se přidat %{smart_count} soubor kvůli vnitřní chybě',
          1: 'Nepodařilo se přidat %{smart_count} soubory kvůli vnitřní chybě',
          2: 'Nepodařilo se přidat %{smart_count} souborů kvůli vnitřní chybě'
        },
        addedNumFiles: {
          0: 'Přidán %{numFiles} soubor',
          1: 'Přidány %{numFiles} soubory',
          2: 'Přidáno %{numFiles} souborů'
        },
        addingMoreFiles: 'Přidávání dalších souborů',
        additionalRestrictionsFailed: {
          0: '%{count} další omezení nebylo splněno',
          1: '%{count} další omezení nebyla splněna',
          2: '%{count} další omezení nebyly splněny'
        },
        addMore: 'Přidat další',
        addMoreFiles: 'Přidat další soubory',
        aggregateExceedsSize: 'Vybrali jste %{size} souborů, ale maximální povolená velikost je %{sizeAllowed}',
        allFilesFromFolderNamed: 'Všechny soubory ze složky %{name}',
        allowAccessDescription: 'Pokud chcete pořizovat fotografie vaším zařízením, povolte prosím přístup ke kameře.',
        allowAccessTitle: 'Povolte prosím přístup ke kameře.',
        allowAudioAccessDescription: 'Chcete-li nahrávat zvuk, povolte pro tento web přístup k mikrofonu.',
        allowAudioAccessTitle: 'Povolte přístup ke svému mikrofonu',
        aspectRatioLandscape: 'Oříznout krajinně (16:9)',
        aspectRatioPortrait: 'Oříznout portrétově (9:16)',
        aspectRatioSquare: 'Oříznout čtvercově',
        authAborted: 'Autentizace byla přerušena',
        authenticate: 'Připojit',
        authenticateWith: 'Připojit k %{pluginName}',
        authenticateWithTitle: 'Prosím přihlaste se k %{pluginName} pro výběr souborů',
        back: 'Zpět',
        browse: 'procházet',
        browseFiles: 'procházet soubory',
        browseFolders: 'procházet složky',
        cancel: 'Zrušit',
        cancelUpload: 'Zrušit nahrávání',
        closeModal: 'Zavřít dialog',
        companionError: 'Spojení s modulem Companion se nezdařilo',
        companionUnauthorizeHint: 'Chcete-li zrušit autorizaci k vašemu %{provider} účtu, přejděte prosím na %{url}',
        complete: 'Hotovo',
        compressedX: {
          0: 'Uložen %{size} komprimovaný obrázek',
          1: 'Uloženy %{size} komprimované obrázky',
          2: 'Uloženo %{size} komprimovaných obrázků'
        },
        compressingImages: 'Komprese obrázků...',
        connectedToInternet: 'Připojeno k internetu',
        copyLink: 'Zkopírovat odkaz',
        copyLinkToClipboardFallback: 'Zkopírujte odkaz níže',
        copyLinkToClipboardSuccess: 'Odkaz zkopírován do schránky',
        creatingAssembly: 'Nahrávání se připravuje...',
        creatingAssemblyFailed: 'Transloadit: Nelze vytvořit Assembly',
        dashboardTitle: 'Nahrát soubory',
        dashboardWindowTitle: 'Okno pro nahrání souborů. (Stiskněte ESC pro zavření.)',
        dataUploadedOfTotal: '%{complete} z %{total}',
        dataUploadedOfUnknown: {
          0: '%{complete} neznámý',
          1: '%{complete} neznámý',
          2: '%{complete} neznámých'
        },
        discardMediaFile: 'Zahodit mediální soubor',
        discardRecordedFile: 'Zahodit nahraný soubor',
        done: 'Dokončeno',
        dropHint: 'Přetáhněte soubory sem',
        dropPasteBoth: 'Přetáhněte soubory sem, vložte je, nebo %{browse}',
        dropPasteFiles: 'Přetáhněte soubory sem, vložte je, nebo %{browse}',
        dropPasteFolders: 'Přetáhněte soubory sem, vložte je, nebo %{browse}',
        dropPasteImportBoth: 'Přetáhněte soubory sem, vložte je, %{browse} nebo je importujte',
        dropPasteImportFiles: 'Přetáhněte soubory sem, vložte je, %{browse} nebo je importujte',
        dropPasteImportFolders: 'Přetáhněte soubory sem, vložte je, %{browse} nebo je importujte',
        editFile: 'Upravit soubor',
        editFileWithFilename: 'Upravit soubor %{file}',
        editImage: 'Upravit obrázek',
        editing: 'Upravujete %{file}',
        emptyFolderAdded: 'Nebyly přidány žádné soubory, adresář je prázdný',
        encoding: 'Převádění...',
        enterCorrectUrl: 'Chybná URL: Ujistěte se, že vkládáte přímý odkaz na soubor',
        enterTextToSearch: 'Vložte text pro vyhledání obrázků',
        enterUrlToImport: 'Vložte URL pro import souboru',
        error: 'Chyba',
        exceedsSize: 'Tento soubor překračuje maximální povolenou velikost: %{size}',
        failedToFetch: 'Modulu Companion se nepodařilo stáhnout soubor z této URL, zkontrolujte prosím, jestli je URL správná',
        failedToUpload: 'Nepodařilo se nahrát soubor %{file}',
        fileSource: 'Zdroj souboru: %{name}',
        filesUploadedOfTotal: {
          0: '%{complete} z %{smart_count} souboru nahráno',
          1: '%{complete} z %{smart_count} souborů nahráno',
          2: '%{complete} z %{smart_count} souborů nahráno'
        },
        filter: 'Filtrovat',
        finishEditingFile: 'Dokončit editaci souboru',
        flipHorizontal: 'Překlopit vodorovně',
        folderAdded: {
          0: 'Přidán %{smart_count} soubor z adresáře %{folder}',
          1: 'Přidány %{smart_count} soubory z adresáře %{folder}',
          2: 'Přidáno %{smart_count} souborů z adresáře %{folder}'
        },
        folderAlreadyAdded: 'Složka "%{folder}" již byla přidána',
        generatingThumbnails: 'Vytváří se miniatury...',
        import: 'Importovat',
        importFiles: 'Importovat soubory z:',
        importFrom: 'Importovat z %{name}',
        inferiorSize: 'Tento soubor je menší než povolená velikost %{size}',
        loadedXFiles: {
          0: 'Načten %{numFiles} soubor',
          1: 'Načteny %{smart_count} soubory',
          2: 'Načteno %{smart_count} souborů'
        },
        loading: 'Nahrávání...',
        logIn: 'Přihlásit se',
        logOut: 'Odhlásit',
        micDisabled: 'Přístup k mikrofonu odepřen uživatelem',
        missingRequiredMetaField: 'Chybí povinná meta pole',
        missingRequiredMetaFieldOnFile: 'Chybí povinná meta pole v %{fileName}',
        missingRequiredMetaFields: {
          0: 'Chybí povinné pole metadat: %{fields}.',
          1: 'Chybí povinná pole metadat: %{fields}.',
          2: 'Chybí povinná pole metadat: %{fields}.'
        },
        myDevice: 'Moje zařízení',
        noAudioDescription: 'Chcete-li nahrávat zvuk, připojte mikrofon nebo jiné vstupní zvukové zařízení',
        noAudioTitle: 'Mikrofon není k dispozici',
        noCameraDescription: 'Chcete-li pořizovat snímky nebo nahrávat video, připojte kameru',
        noCameraTitle: 'Kamera není k dispozici',
        noDuplicates: "Nelze znovu přidat stejný soubor '%{fileName}'",
        noFilesFound: 'Nenalezeny žádné soubory ani adresáře',
        noInternetConnection: 'Nepřipojeno k internetu',
        noMoreFilesAllowed: 'Nelze přidat další soubory',
        noSearchResults: 'Bohužel pro toto hledání nejsou žádné výsledky',
        openFolderNamed: 'Otevřít adresář %{name}',
        pause: 'Pozastavit',
        paused: 'Pozastaveno',
        pauseUpload: 'Pozastavit nahrávání',
        pickFiles: 'Vyberte soubory',
        pickPhotos: 'Vyberte fotografie',
        pleaseWait: 'Prosím čekejte',
        pluginNameAudio: 'Zvuk',
        pluginNameCamera: 'Kamera',
        pluginNameScreenCapture: 'Záznam obrazovky',
        pluginNameUrl: 'Odkaz',
        pluginWebdavInputLabel: 'WebDAV URL souboru (např. z ownCloudu nebo Nextcloudu)',
        poweredBy: 'Vytvořeno pomocí %{uppy}',
        processingXFiles: {
          0: 'Zpracování %{smart_count} souboru',
          1: 'Zpracování %{smart_count} souborů',
          2: 'Zpracování %{smart_count} souborů'
        },
        recording: 'Záznam',
        recordingLength: 'Délka nahrávky %{recording_length}',
        recordingStoppedMaxSize: 'Nahrávání bylo zastaveno, protože velikost souboru brzy překročí limit',
        recordVideoBtn: 'Záznam videa',
        recoveredAllFiles: 'Obnovili jsme všechny soubory. Nyní můžete pokračovat v nahrávání.',
        recoveredXFiles: {
          0: 'Nepodařilo se nám plně obnovit 1 soubor. Vyberte jej znovu a obnovte nahrávání.',
          1: 'Nepodařilo se nám plně obnovit %{smart_count} soubory. Vyberte je znovu a obnovte nahrávání.',
          2: 'Nepodařilo se nám plně obnovit %{smart_count} souborů. Vyberte je znovu a obnovte nahrávání.'
        },
        removeFile: 'Odebrat soubor',
        reSelect: 'Re-výběr',
        resetFilter: 'Reset filtru',
        resetSearch: 'Resetovat vyhledávání',
        resume: 'Pokřačovat',
        resumeUpload: 'Pokračovat v nahrávání',
        retry: 'Opakovat',
        retryUpload: 'Opakovat nahrávání',
        revert: 'Resetovat',
        rotate: 'Otočit o 90°',
        save: 'Uložit',
        saveChanges: 'Uložit změny',
        search: 'Vyhledat',
        searchImages: 'Vyhledat obrázky',
        selectX: {
          0: 'Vybrat %{smart_count}',
          1: 'Vybrat %{smart_count}',
          2: 'Vybrat %{smart_count}'
        },
        sessionRestored: 'Relace obnovena',
        showErrorDetails: 'Zobrazit podrobnosti o chybě',
        signInWithGoogle: 'Přihlaste se pomocí Google',
        smile: 'Úsměv prosím!',
        startAudioRecording: 'Spustit nahrávání zvuku',
        startCapturing: 'Spustit snímání obrazovky',
        startRecording: 'Spustit nahrávání videa',
        stopAudioRecording: 'Zastavit nahrávání zvuku',
        stopCapturing: 'Zastavit snímání obrazovky',
        stopRecording: 'Zastavit nahrávání videa',
        streamActive: 'Stream je aktivní',
        streamPassive: 'Stream je pasivní',
        submitRecordedFile: 'Odeslat nahraný soubor',
        takePicture: 'Pořídit fotografii',
        takePictureBtn: 'Pořídit fotografii',
        takeScreenshot: 'Pořídit snímek obrazovky',
        unselectFileNamed: 'Zrušit výběr souboru %{name}',
        unnamed: 'Nepojmenovaný',
        upload: 'Nahrát',
        uploadComplete: 'Nahrání dokončeno',
        uploadFailed: 'Nahrání se nezdařilo',
        uploading: 'Nahrávání',
        uploadingXFiles: {
          0: 'Nahrávání %{smart_count} souboru',
          1: 'Nahrávání %{smart_count} souborů',
          2: 'Nahrávání %{smart_count} souborů'
        },
        uploadPaused: 'Nahrání dokončeno',
        uploadStalled: 'Nahrávání neproběhlo po dobu %{seconds} sekund. Možná to budete chtít zkusit znovu.',
        uploadXFiles: {
          0: 'Nahrát %{smart_count} soubor',
          1: 'Nahrát %{smart_count} soubory',
          2: 'Nahrát %{smart_count} souborů'
        },
        uploadXNewFiles: {
          0: 'Nahrát +%{smart_count} soubor',
          1: 'Nahrát +%{smart_count} soubory',
          2: 'Nahrát +%{smart_count} souborů'
        },
        xFilesSelected: {
          0: '%{smart_count} soubor vybrán',
          1: '%{smart_count} soubory vybrány',
          2: '%{smart_count} souborů vybráno'
        },
        xMoreFilesAdded: {
          0: '%{smart_count} další soubor přidán',
          1: '%{smart_count} další soubory přidány',
          2: '%{smart_count} dalších souborů přidáno'
        },
        xTimeLeft: '%{time} zbývá',
        youCanOnlyUploadFileTypes: 'Lze nahrát pouze následující typy souborů: %{types}',
        youCanOnlyUploadX: {
          0: 'Lze nahrát pouze %{smart_count} soubor',
          1: 'Lze nahrát pouze %{smart_count} soubory',
          2: 'Lze nahrát pouze %{smart_count} souborů'
        },
        youHaveToAtLeastSelectX: {
          0: 'Je třeba vybrat alespoň %{smart_count} soubor',
          1: 'Je třeba vybrat alespoň %{smart_count} soubory',
          2: 'Je třeba vybrat alespoň %{smart_count} souborů'
        },
        zoomIn: 'Přiblížit',
        zoomOut: 'Oddálit'

      }
    }
  }
})
