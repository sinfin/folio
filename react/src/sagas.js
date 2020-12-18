import { filesSagas } from 'ducks/files'
import { uploadsSagas } from 'ducks/uploads'
import { displaySagas } from 'ducks/display'
import { filtersSagas } from 'ducks/filters'
import { concat } from 'lodash'

export default concat(filesSagas, uploadsSagas, displaySagas, filtersSagas)
