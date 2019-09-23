import 'react-app-polyfill/ie11'
import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import { createStore, applyMiddleware } from 'redux'
import createSagaMiddleware from 'redux-saga'

import App from 'containers/App'
import MenuFormApp from 'containers/MenuFormApp'
import { setMode, setFileType } from 'ducks/app'
import { setMenusData } from 'ducks/menus'
import { setAtomsData } from 'ducks/atoms'
import { setOriginalPlacements, setAttachmentable, setPlacementType } from 'ducks/filePlacements'
import fileTypeToKey from 'utils/fileTypeToKey'

import reducers from './reducers'
import sagas from './sagas'

// import registerServiceWorker from './registerServiceWorker'

window.folioConsoleInitReact = (domRoot) => {
  const sagaMiddleware = createSagaMiddleware()
  const store = createStore(reducers, {}, applyMiddleware(sagaMiddleware))

  sagas.forEach((saga) => sagaMiddleware.run(saga))
  store.runSaga = sagaMiddleware.run
  store.asyncReducers = {} // Async reducer registry

  if (domRoot.classList.contains('folio-react-wrap--menu-form')) {
    store.dispatch(setMenusData({
      paths: JSON.parse(domRoot.dataset.menupaths),
      items: JSON.parse(domRoot.dataset.menuitems),
      maxNestingDepth: parseInt(domRoot.dataset.menudepth)
    }))

    ReactDOM.render((
      <Provider store={store}>
        <MenuFormApp />
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
        key: 'atoms',
        action: setAtomsData,
        asJson: true
      }
    ]
    DOM_DATA.forEach(({ key, action, asJson }) => {
      let data = domRoot.dataset[key] || null
      if (data) {
        if (asJson) data = JSON.parse(data)
        store.dispatch(action(data))
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
    let filesKey
    if (fileType) {
      filesKey = fileTypeToKey(fileType)

      KEYED_DOM_DATA.forEach(({ key, action, asJson }) => {
        let data = domRoot.dataset[key] || null
        if (data) {
          if (asJson) data = JSON.parse(data)
          store.dispatch(action(filesKey, data))
        }
      })
    }

    ReactDOM.render((
      <Provider store={store}>
        <App />
      </Provider>
    ), domRoot)
  }
}

const DOM_ROOTS = document.querySelectorAll('.folio-react-wrap')

for (let i = 0; i < DOM_ROOTS.length; ++i) {
  window.folioConsoleInitReact(DOM_ROOTS[i])
}
