import { combineReducers } from 'redux'

import appReducer from 'ducks/app'
import filesReducer from 'ducks/files'
import uploadsReducer from 'ducks/uploads'
import filtersReducer from 'ducks/filters'
import displayReducer from 'ducks/display'
import modalReducer from 'ducks/modal'

export default combineReducers({
  app: appReducer,
  files: filesReducer,
  uploads: uploadsReducer,
  filters: filtersReducer,
  display: displayReducer,
  modal: modalReducer,
})
