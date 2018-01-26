import { filesSagas } from 'ducks/files'
import { concat } from 'lodash'

export default concat(filesSagas)
