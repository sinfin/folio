import { combineReducers } from 'redux'

import ancestryReducer from 'ducks/ancestry'
import appReducer from 'ducks/app'
import atomsReducer from 'ducks/atoms'
import displayReducer from 'ducks/display'
import fileModalReducer from 'ducks/fileModal'
import filePlacementsReducer from 'ducks/filePlacements'
import filesReducer from 'ducks/files'
import filtersReducer from 'ducks/filters'
import menusReducer from 'ducks/menus'
import orderedMultiselectReducer from 'ducks/orderedMultiselect'
import uploadsReducer from 'ducks/uploads'

export default combineReducers({
  ancestry: ancestryReducer,
  app: appReducer,
  atoms: atomsReducer,
  display: displayReducer,
  fileModal: fileModalReducer,
  filePlacements: filePlacementsReducer,
  files: filesReducer,
  filters: filtersReducer,
  menus: menusReducer,
  orderedMultiselect: orderedMultiselectReducer,
  uploads: uploadsReducer
})
