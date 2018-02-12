import { filesSagas } from 'ducks/files'
import { uploadsSagas } from 'ducks/uploads'
import { concat } from 'lodash'

export default concat(filesSagas, uploadsSagas)
