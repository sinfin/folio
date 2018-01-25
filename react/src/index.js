import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'

import './index.css'
import reducers from './reducers'
import App from './App'
import registerServiceWorker from './registerServiceWorker'

const store = createStore(reducers)

ReactDOM.render((
  <Provider store={store}>
    <App />
  </Provider>
), document.getElementById('folio-react-images'))

registerServiceWorker()
