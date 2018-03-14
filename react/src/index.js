import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import { createStore, applyMiddleware } from 'redux'
import createSagaMiddleware from 'redux-saga'
import { fromJS } from 'immutable'

import App from 'containers/App'
import { setMode, setFileType } from 'ducks/app'
import { prefillSelected, setAttachmentable } from 'ducks/files'

import reducers from './reducers'
import sagas from './sagas'
// import registerServiceWorker from './registerServiceWorker'

window.folioConsoleInitReact = (domRoot) => {
  const sagaMiddleware = createSagaMiddleware()

  const store = createStore(reducers, fromJS({}), applyMiddleware(sagaMiddleware))

  const DOM_DATA = [
    {
      key: 'mode',
      action: setMode,
      asJson: false,
    },
    {
      key: 'selected',
      action: prefillSelected,
      asJson: true,
    },
    {
      key: 'fileType',
      action: setFileType,
      asJson: false,
    },
    {
      key: 'attachmentable',
      action: setAttachmentable,
      asJson: false,
    },
  ]
  DOM_DATA.forEach(({ key, action, asJson }) => {
    let data = domRoot.dataset[key] || null
    if (data) {
      if (asJson) data = JSON.parse(data)
      store.dispatch(action(data))
    }
  })

  sagas.forEach((saga) => sagaMiddleware.run(saga))

  store.runSaga = sagaMiddleware.run
  store.asyncReducers = {} // Async reducer registry

  ReactDOM.render((
    <Provider store={store}>
      <App />
    </Provider>
  ), domRoot)

  // registerServiceWorker()
}

const DOM_ROOTS = document.querySelectorAll('.folio-react-wrap')

for (let i = 0; i < DOM_ROOTS.length; ++i) {
  window.folioConsoleInitReact(DOM_ROOTS[i])
}
