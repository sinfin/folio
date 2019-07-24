import { combineReducers } from 'redux'

import appReducer from 'ducks/app'
import atomsReducer from 'ducks/atoms'
import displayReducer from 'ducks/display'
import filePlacementsReducer from 'ducks/filePlacements'
import filesReducer from 'ducks/files'
import filtersReducer from 'ducks/filters'
import modalReducer from 'ducks/modal'
import uploadsReducer from 'ducks/uploads'

export default combineReducers({
  app: appReducer,
  atoms: atomsReducer,
  display: displayReducer,
  filePlacements: filePlacementsReducer,
  files: filesReducer,
  filters: filtersReducer,
  modal: modalReducer,
  uploads: uploadsReducer
})
