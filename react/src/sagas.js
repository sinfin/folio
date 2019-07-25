import { concat } from 'lodash'
import { atomsSagas } from 'ducks/atoms'
import { displaySagas } from 'ducks/display'
import { filesSagas } from 'ducks/files'
import { uploadsSagas } from 'ducks/uploads'

export default concat(filesSagas, uploadsSagas, displaySagas, atomsSagas)
