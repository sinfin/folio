import { concat } from 'lodash'

import { atomsSagas } from 'ducks/atoms'
import { displaySagas } from 'ducks/display'
import { filesSagas } from 'ducks/files'
import { filtersSagas } from 'ducks/filters'
import { uploadsSagas } from 'ducks/uploads'
import { filePlacementsSagas } from 'ducks/filePlacements'
import { fileModalSagas } from 'ducks/fileModal'

export default concat(filesSagas, uploadsSagas, displaySagas, atomsSagas, filtersSagas, filePlacementsSagas, fileModalSagas)
