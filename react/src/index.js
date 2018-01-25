import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import { createStore, applyMiddleware } from 'redux'
import createSagaMiddleware from 'redux-saga'
import { fromJS } from 'immutable'

import App from 'containers/App'

import './index.css'
import reducers from './reducers'
import sagas from './sagas'
import registerServiceWorker from './registerServiceWorker'

const sagaMiddleware = createSagaMiddleware()

const store = createStore(reducers, fromJS({}), applyMiddleware(sagaMiddleware))

sagas.forEach((saga) => sagaMiddleware.run(saga))

store.runSaga = sagaMiddleware.run
store.asyncReducers = {} // Async reducer registry

ReactDOM.render((
  <Provider store={store}>
    <App />
  </Provider>
), document.getElementById('folio-react-images'))

registerServiceWorker()
