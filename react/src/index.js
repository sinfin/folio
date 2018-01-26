import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import { createStore, applyMiddleware } from 'redux'
import createSagaMiddleware from 'redux-saga'
import { fromJS } from 'immutable'

import App from 'containers/App'
import { setMode } from 'ducks/app'
import { prefillSelected } from 'ducks/files'
import { setUploadsUrl, setUploadsType } from 'ducks/uploads'

import './index.css'
import reducers from './reducers'
import sagas from './sagas'
import registerServiceWorker from './registerServiceWorker'

const DOM_ROOT = document.querySelector('.folio-react-wrap')

if (DOM_ROOT) {
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
      key: 'uploadUrl',
      action: setUploadsUrl,
      asJson: false,
    },
    {
      key: 'uploadType',
      action: setUploadsType,
      asJson: false,
    },
  ]
  DOM_DATA.forEach(({ key, action, asJson }) => {
    let data = DOM_ROOT.dataset[key] || null
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
  ), DOM_ROOT)

  registerServiceWorker()
}
