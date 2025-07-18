import 'react-app-polyfill/ie11'
import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import { createStore, applyMiddleware } from 'redux'
import createSagaMiddleware from 'redux-saga'
import 'url-search-params-polyfill'

import FilesApp from 'containers/FilesApp'
import AncestryApp from 'containers/AncestryApp'
import MenuFormApp from 'containers/MenuFormApp'
import OrderedMultiselectApp from 'containers/OrderedMultiselectApp'
import NotesFieldsApp from 'containers/NotesFieldsApp'
import { setMode, setFileType, setFilesUrl, setIndexUrl, setReadOnly, setTaggable, setNoFileUsage, setFileReactType, setCanDestroyFiles, setPhotoArchiveEnabled } from 'ducks/app'
import { setMenusData } from 'ducks/menus'
import { openFileModal } from 'ducks/fileModal'
import { setAncestryData } from 'ducks/ancestry'
import { setAtomsData } from 'ducks/atoms'
import { setOriginalPlacements, setAttachmentable, setPlacementType } from 'ducks/filePlacements'
import { setOrderedMultiselectData } from 'ducks/orderedMultiselect'
import { setNotesFieldsData } from 'ducks/notesFields'

import reducers from './reducers'
import sagas from './sagas'

// import registerServiceWorker from './registerServiceWorker'

window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.React = {}

window.FolioConsole.React.init = (domRoot) => {
  const sagaMiddleware = createSagaMiddleware()
  const store = createStore(reducers, {}, applyMiddleware(sagaMiddleware))

  sagas.forEach((saga) => sagaMiddleware.run(saga))
  store.runSaga = sagaMiddleware.run
  store.asyncReducers = {} // Async reducer registry

  if (domRoot.classList.contains('folio-react-wrap--menu-form')) {
    store.dispatch(setMenusData({
      paths: JSON.parse(domRoot.dataset.menupaths),
      items: JSON.parse(domRoot.dataset.menuitems),
      styles: JSON.parse(domRoot.dataset.menustyles),
      maxNestingDepth: parseInt(domRoot.dataset.menudepth)
    }))

    ReactDOM.render((
      <Provider store={store}>
        <MenuFormApp />
      </Provider>
    ), domRoot)
  } else if (domRoot.classList.contains('folio-react-wrap--notes-fields')) {
    store.dispatch(setNotesFieldsData({
      domRoot,
      notes: domRoot.dataset.notes ? JSON.parse(domRoot.dataset.notes) : [],
      label: domRoot.dataset.label,
      paramBase: domRoot.dataset.paramBase,
      accountId: domRoot.dataset.accountId,
      errorsHtml: domRoot.dataset.errorsHtml,
      targetType: domRoot.dataset.targetType,
      targetId: domRoot.dataset.targetId,
      url: domRoot.dataset.url,
      classNameParent: domRoot.dataset.classNameParent,
      classNameTooltipParent: domRoot.dataset.classNameTooltipParent
    }))

    ReactDOM.render((
      <Provider store={store}>
        <NotesFieldsApp />
      </Provider>
    ), domRoot)
  } else if (domRoot.classList.contains('folio-react-wrap--ordered-multiselect')) {
    store.dispatch(setOrderedMultiselectData({
      items: JSON.parse(domRoot.dataset.items),
      removedIds: JSON.parse(domRoot.dataset.removedIds),
      paramBase: domRoot.dataset.paramBase,
      foreignKey: domRoot.dataset.foreignKey,
      url: domRoot.dataset.url,
      sortable: domRoot.dataset.sortable !== '0',
      atomSetting: domRoot.dataset.atomSetting,
      menuPlacement: domRoot.dataset.menuPlacement
    }))

    ReactDOM.render((
      <Provider store={store}>
        <OrderedMultiselectApp />
      </Provider>
    ), domRoot)
  } else if (domRoot.classList.contains('folio-react-wrap--ancestry')) {
    store.dispatch(setAncestryData({
      items: JSON.parse(domRoot.dataset.items),
      maxNestingDepth: parseInt(domRoot.dataset.maxNestingDepth)
    }))

    ReactDOM.render((
      <Provider store={store}>
        <AncestryApp />
      </Provider>
    ), domRoot)
  } else {
    const DOM_DATA = [
      {
        key: 'mode',
        action: setMode,
        asJson: false
      },
      {
        key: 'fileType',
        action: setFileType,
        asJson: false
      },
      {
        key: 'reactType',
        action: setFileReactType,
        asJson: false
      },
      {
        key: 'indexUrl',
        action: setIndexUrl,
        asJson: false
      },
      {
        key: 'filesUrl',
        action: setFilesUrl,
        asJson: false
      },
      {
        key: 'noFileUsage',
        action: setNoFileUsage,
        asJson: false
      },
      {
        key: 'readOnly',
        action: setReadOnly,
        asJson: false
      },
      {
        key: 'taggable',
        action: setTaggable,
        asJson: false
      },
      {
        key: 'canDestroyFiles',
        action: setCanDestroyFiles,
        asJson: false,
        fallbackValue: false
      },
      {
        key: 'photoArchiveEnabled',
        action: setPhotoArchiveEnabled,
        asJson: false,
        fallbackValue: false
      },
      {
        key: 'atoms',
        action: setAtomsData,
        asJson: true
      }
    ]
    DOM_DATA.forEach(({ key, action, asJson, fallbackValue }) => {
      let data = domRoot.dataset[key] || null
      if (data) {
        if (asJson) data = JSON.parse(data)
        store.dispatch(action(data))
      } else if (typeof fallbackValue !== 'undefined') {
        store.dispatch(action(fallbackValue))
      }
    })

    const KEYED_DOM_DATA = [
      {
        key: 'attachmentable',
        action: setAttachmentable,
        asJson: false
      },
      {
        key: 'placementType',
        action: setPlacementType,
        asJson: false
      },
      {
        key: 'originalPlacements',
        action: setOriginalPlacements,
        asJson: true
      }
    ]

    const fileType = domRoot.dataset.fileType
    if (fileType) {
      KEYED_DOM_DATA.forEach(({ key, action, asJson }) => {
        let data = domRoot.dataset[key] || null
        if (data) {
          if (asJson) data = JSON.parse(data)
          store.dispatch(action(fileType, data))
        }
      })
    }

    const DATA_WITH_TYPE_AND_URL = [
      {
        key: 'fileForModal',
        action: openFileModal,
        asJson: true
      }
    ]

    const filesUrl = domRoot.dataset.filesUrl

    if (fileType && filesUrl) {
      DATA_WITH_TYPE_AND_URL.forEach(({ key, action, asJson }) => {
        let data = domRoot.dataset[key] || null
        if (data) {
          if (asJson) data = JSON.parse(data)
          store.dispatch(action(fileType, filesUrl, data))
        }
      })
    }

    ReactDOM.render((
      <Provider store={store}>
        <FilesApp />
      </Provider>
    ), domRoot)
  }
}

window.FolioConsole.React.destroy = (domRoot) => {
  ReactDOM.unmountComponentAtNode(domRoot)
}

const DOM_ROOTS = document.querySelectorAll('.folio-react-wrap')

for (let i = 0; i < DOM_ROOTS.length; ++i) {
  window.FolioConsole.React.init(DOM_ROOTS[i])
}
