import { mapValues, sortBy, omit } from 'lodash'
import { takeEvery, call, select, put } from 'redux-saga/effects'

import { apiHtmlPost, apiPost } from 'utils/api'
import timestamp from 'utils/timestamp'

import { setOriginalPlacements } from 'ducks/filePlacements'

// Constants

const SET_ATOMS_DATA = 'atoms/SET_ATOMS_DATA'
const NEW_ATOMS = 'atoms/NEW_ATOMS'
const EDIT_ATOMS = 'atoms/EDIT_ATOMS'
const REMOVE_ATOMS = 'atoms/REMOVE_ATOMS'
const VALIDATE_AND_SAVE_FORM_ATOMS = 'atoms/VALIDATE_AND_SAVE_FORM_ATOMS'
const SAVE_FORM_ATOMS = 'atoms/SAVE_FORM_ATOMS'
const CLOSE_FORM_ATOM = 'atoms/CLOSE_FORM_ATOM'
const UPDATE_FORM_ATOM_TYPE = 'atoms/UPDATE_FORM_ATOM_TYPE'
const UPDATE_FORM_ATOM_VALUE = 'atoms/UPDATE_FORM_ATOM_VALUE'
const MOVE_ATOMS_TO_INDEX = 'atoms/MOVE_ATOMS_TO_INDEX'
const UPDATE_FORM_ATOM_ATTACHMENTS = 'atoms/UPDATE_FORM_ATOM_ATTACHMENTS'
const REMOVE_FORM_ATOM_ATTACHMENT = 'atoms/REMOVE_FORM_ATOM_ATTACHMENT'
const SET_FORM_ATOM_FILE_PLACEMENTS = 'atoms/SET_FORM_ATOM_FILE_PLACEMENTS'
const SET_FORM_VALIDATION_ERRORS = 'atoms/SET_FORM_VALIDATION_ERRORS'
const UPDATE_FORM_ATOM_ASSOCIATION = 'atoms/UPDATE_FORM_ATOM_ASSOCIATION'

// Actions

export function setAtomsData (data) {
  return { type: SET_ATOMS_DATA, data }
}

export function updateFormAtomType (newType, values) {
  return { type: UPDATE_FORM_ATOM_TYPE, newType, values }
}

export function updateFormAtomValue (index, key, value) {
  return { type: UPDATE_FORM_ATOM_VALUE, index, key, value }
}

export function newAtoms (rootKey, action, indices, atomType) {
  return { type: NEW_ATOMS, rootKey, action, indices, atomType }
}

export function editAtoms (rootKey, indices) {
  return { type: EDIT_ATOMS, rootKey, indices }
}

export function removeAtoms (rootKey, indices) {
  return { type: REMOVE_ATOMS, rootKey, indices }
}

export function moveAtomsToIndex (rootKey, indices, targetIndex, action) {
  return { type: MOVE_ATOMS_TO_INDEX, rootKey, indices, targetIndex, action }
}

export function closeFormAtom () {
  return { type: CLOSE_FORM_ATOM }
}

export function validateAndSaveFormAtom (filePlacements) {
  return { type: VALIDATE_AND_SAVE_FORM_ATOMS, filePlacements }
}

export function saveFormAtoms (filePlacements) {
  return { type: SAVE_FORM_ATOMS, filePlacements }
}

export function updateFormAtomAttachments (attachmentKey, data) {
  return { type: UPDATE_FORM_ATOM_ATTACHMENTS, attachmentKey, data }
}

export function removeFormAtomAttachment (attachmentKey) {
  return { type: REMOVE_FORM_ATOM_ATTACHMENT, attachmentKey }
}

export function setFormAtomFilePlacements () {
  return { type: SET_FORM_ATOM_FILE_PLACEMENTS }
}

export function setFormValidationErrors (response) {
  return { type: SET_FORM_VALIDATION_ERRORS, response }
}

export function updateFormAtomAssociation (index, associationKey, record) {
  return { type: UPDATE_FORM_ATOM_ASSOCIATION, index, associationKey, record }
}

// Selectors

export const atomsSelector = (state) => ({
  ...state.atoms,
  atoms: mapValues(state.atoms.atoms, (collection) => (
    collection.map((atom) => ({
      ...atom,
      meta: state.atoms.structures[atom.type]
    }))
  ))
})

export const atomsFormSelector = (state) => state.atoms.form

export const atomsByIndicesSelector = (substate, rootKey, indices) => {
  const collection = []
  substate.atoms[rootKey].forEach((atom, i) => {
    if (indices.indexOf(i) !== -1) {
      collection.push({
        ...atom,
        meta: substate.structures[atom.type]
      })
    }
  })

  return collection
}

export const atomSelector = (substate, rootKey, index) => {
  const atom = substate.atoms[rootKey][index]

  return {
    ...atom,
    meta: substate.structures[atom.type]
  }
}

export const atomTypesSelector = (state) => {
  const unsorted = Object.keys(state.atoms.structures).map((key) => ({
    key,
    title: state.atoms.structures[key].title
  }))
  return sortBy(unsorted, ['title'])
}

const serializeAtom = (state, atom) => {
  const base = {
    ...omit(atom, ['associations']),
    ...omit(atom.data, ['placement_id']),
    ...atom.associations,
    placement_type: state.atoms.placementType
  }

  Object.keys(base).forEach((key) => {
    if (base[key] === '<p></p>') base[key] = null
  })

  state.atoms.structures[atom.type]['attachments'].forEach(({ key, plural }) => {
    if (!base[key]) return
    if (plural) {
      base[key] = base[key].map((fp) => omit(fp, ['id', 'file']))
    } else {
      base[key] = omit(base[key], ['id', 'file'])
    }
  })

  return omit(base, ['meta', 'timestamp', 'data'])
}

export const serializedAtomsSelector = (state) => {
  const h = {}
  Object.keys(state.atoms.atoms).forEach((rootKey) => {
    h[`${rootKey}_attributes`] = state.atoms.atoms[rootKey].map((atom) => serializeAtom(state, atom))
  })
  return h
}

export const makeSerializedFormAtomsSelector = (action) => (state) => {
  return state.atoms.form.atoms.map((atom) => (
    serializeAtom(state, { atom, ...action.filePlacements, placement_type: state.atoms.placementType })
  ))
}

// Sagas
function * updateAtomPreviews (action) {
  yield put(closeFormAtom())
  const $ = window.jQuery
  const $iframes = $('.f-c-simple-form-with-atoms__iframe')
  $iframes.each((_i, iframe) => {
    $(iframe).parent().addClass('f-c-simple-form-with-atoms__preview--loading')
  })
  const serializedAtoms = yield select(serializedAtomsSelector)

  const $labels = $('.f-c-js-atoms-placement-label')
  if ($labels.length) {
    serializedAtoms['labels'] = {}
    $labels.each((i, label) => {
      const $label = $(label)
      serializedAtoms['labels'][$label.data('locale') || null] = $label.val()
    })
  }
  const $perexes = $('.f-c-js-atoms-placement-perex')
  if ($perexes.length) {
    serializedAtoms['perexes'] = {}
    $perexes.each((i, perex) => {
      const $perex = $(perex)
      serializedAtoms['perexes'][$perex.data('locale') || null] = $perex.val()
    })
  }

  const html = yield (call(apiHtmlPost, '/console/atoms/preview', serializedAtoms))
  $iframes.each((_i, iframe) => {
    const callback = () => {
      if (!iframe.contentWindow.jQuery) { return setTimeout(callback, 100) }
      const $iframe = $(iframe)
      const visibleLocale = $iframe.closest('.f-c-simple-form-with-atoms__preview').find('.f-c-atoms-locale-switch__button--active').data('locale')
      const $body = iframe.contentWindow.jQuery(iframe.contentDocument.body)
      $body.html(html)
      $body.find('.f-c-atoms-previews__locale').each((_i, el) => {
        const $el = iframe.contentWindow.jQuery(el)
        $el.prop('hidden', $el.data('locale') && $el.data('locale') !== visibleLocale)
      })
      iframe.contentWindow.postMessage({ type: 'replacedHtml' }, window.origin)
      $(iframe).parent().removeClass('f-c-simple-form-with-atoms__preview--initializing f-c-simple-form-with-atoms__preview--loading')
    }
    callback()
  })
  if (action.type !== SET_ATOMS_DATA) {
    window.postMessage({ type: 'setFormAsDirty' }, window.origin)
  }
}

function * updateAtomPreviewsSaga () {
  yield [
    takeEvery(REMOVE_ATOMS, updateAtomPreviews),
    takeEvery(MOVE_ATOMS_TO_INDEX, updateAtomPreviews),
    takeEvery(SAVE_FORM_ATOMS, updateAtomPreviews),
    takeEvery(SET_ATOMS_DATA, updateAtomPreviews)
  ]
}

function * showAtomsForm (action) {
  window.jQuery('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--editing-atom')
  yield put(setFormAtomFilePlacements())
}

function * showAtomsFormSaga () {
  yield [
    takeEvery(NEW_ATOMS, showAtomsForm),
    takeEvery(EDIT_ATOMS, showAtomsForm)
  ]
}

function * hideAtomsForm (action) {
  yield window.jQuery('.f-c-simple-form-with-atoms').removeClass('f-c-simple-form-with-atoms--editing-atom')
}

function * hideAtomsFormSaga () {
  yield takeEvery(CLOSE_FORM_ATOM, hideAtomsForm)
}

function * setAtomFilePlacements (action) {
  const form = yield select(atomsFormSelector)
  yield put(setOriginalPlacements('images', form.atom.image_placements_attributes || []))
  yield put(setOriginalPlacements('documents', form.atom.document_placement_attributes || []))
}

function * setAtomFilePlacementsSaga () {
  yield takeEvery(SET_FORM_ATOM_FILE_PLACEMENTS, setAtomFilePlacements)
}

function * validateAndSaveFormAtomPerform (action) {
  const serializedForm = yield select(makeSerializedFormAtomsSelector(action))
  const response = yield (call(apiPost, '/console/atoms/validate', serializedForm))
  if (response.valid) {
    yield put(saveFormAtoms(action.filePlacements))
  } else {
    yield put(setFormValidationErrors(response))
  }
}

function * validateAndSaveFormAtomSaga () {
  yield takeEvery(VALIDATE_AND_SAVE_FORM_ATOMS, validateAndSaveFormAtomPerform)
}

export const atomsSagas = [
  updateAtomPreviewsSaga,
  showAtomsFormSaga,
  hideAtomsFormSaga,
  setAtomFilePlacementsSaga,
  validateAndSaveFormAtomSaga
]

// State

export const DEFAULT_FORM_ATOM_STATE = {
  atom: null,
  valid: null,
  validating: false,
  errors: {},
  messages: []
}

export const initialState = {
  atoms: {},
  destroyedIds: {},
  namespace: null,
  structures: {},
  placementType: null,
  form: {
    rootKey: null,
    indices: null,
    action: null,
    dirty: false,
    edit: false,
    destroyedIds: [],
    atoms: []
  }
}

// Reducer

function atomsReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ATOMS_DATA: {
      const atoms = {}
      let i = 1
      Object.keys(action.data.atoms).forEach((atomsKey) => {
        atoms[atomsKey] = action.data.atoms[atomsKey].map((atom) => {
          const timestamp = i += 1
          return {
            ...atom,
            timestamp: timestamp
          }
        })
      })

      return {
        ...state,
        ...action.data,
        atoms
      }
    }

    case NEW_ATOMS: {
      return {
        ...state,
        form: {
          ...initialState.form,
          dirty: true,
          rootKey: action.rootKey,
          indices: action.indices,
          action: action.action,
          edit: false,
          atoms: [
            {
              ...DEFAULT_FORM_ATOM_STATE,
              atom: {
                id: null,
                type: action.atomType,
                data: {},
                timestamp: timestamp(),
                meta: state.structures[action.atomType],
                associations: {}
              }
            }
          ]
        }
      }
    }

    case EDIT_ATOMS:
      return {
        ...state,
        form: {
          ...initialState.form,
          rootKey: action.rootKey,
          indices: action.indices,
          edit: true,
          atoms: atomsByIndicesSelector(state, action.rootKey, action.indices).map((atom) => ({
            ...DEFAULT_FORM_ATOM_STATE,
            atom
          }))
        }
      }

    case REMOVE_ATOMS: {
      const destroyedIds = []
      const atoms = []

      state.atoms[action.rootKey].forEach((atom, i) => {
        if (action.indices.indexOf(i) === -1) {
          atoms.push(atom)
        } else {
          if (atom.id) {
            destroyedIds.push(atom.id)
          }
        }
      })

      return {
        ...state,
        destroyedIds: {
          ...state.destroyedIds,
          [action.rootKey]: [...state.destroyedIds[action.rootKey], ...destroyedIds]
        },
        atoms: {
          ...state.atoms,
          [action.rootKey]: atoms
        }
      }
    }

    case CLOSE_FORM_ATOM:
      return {
        ...state,
        form: {
          ...initialState.form
        }
      }

    case SAVE_FORM_ATOMS: {
      const destroyedIds = {
        ...state.destroyedIds,
        [state.form.rootKey]: [
          ...state.destroyedIds[state.form.rootKey],
          ...state.form.destroyedIds
        ]
      }

      let atoms = []
      const newAtoms = state.form.atoms.map((atom) => ({
        ...omit(atom.atom, ['meta', 'id']),
        ...action.filePlacements,
        timestamp: timestamp()
      }))

      switch (state.form.action) {
        case 'prepend':
          atoms = [...newAtoms, ...state.atoms[state.form.rootKey]]
          break
        case 'append':
          atoms = [...state.atoms[state.form.rootKey], ...newAtoms]
          break
        default: {
          if (state.form.edit) {
            state.atoms[state.form.rootKey].forEach((atom, i) => {
              if (state.form.indices.indexOf(i) === -1) {
                atoms.push(atom)
              } else if (i === state.form.indices[0]) {
                atoms = [...atoms, ...newAtoms]
              }
            })
          } else {
            state.atoms[state.form.rootKey].forEach((atom, i) => {
              if (state.form.indices.indexOf(i) === -1) {
                atoms.push(atom)
              } else if (i === state.form.indices[0]) {
                atoms = [...atoms, ...newAtoms, atom]
              }
            })
          }
        }
      }

      return {
        ...state,
        destroyedIds,
        atoms: {
          ...state.atoms,
          [state.form.rootKey]: atoms
        },
        form: {
          ...initialState.form
        }
      }
    }

    case VALIDATE_AND_SAVE_FORM_ATOMS:
      return {
        ...state,
        form: {
          ...state.form,
          atoms: state.form.atoms.map((atom) => ({
            ...atom,
            validating: true
          }))
        }
      }

    case UPDATE_FORM_ATOM_TYPE: {
      const destroyedIds = []

      state.form.atoms.forEach((atom) => {
        if (atom.atom.id) {
          destroyedIds.push(atom.atom.id)
        }
      })

      return {
        ...state,
        form: {
          ...state.form,
          destroyedIds,
          dirty: true,
          atoms: [
            {
              ...DEFAULT_FORM_ATOM_STATE,
              atom: {
                id: null,
                type: action.newType,
                data: action.values,
                timestamp: timestamp(),
                meta: state.structures[action.newType],
                associations: {}
              }
            }
          ]
        }
      }
    }

    case UPDATE_FORM_ATOM_VALUE:
      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              return {
                ...atom,
                atom: {
                  ...atom.atom,
                  data: {
                    ...atom.atom.data,
                    [action.key]: action.value
                  }
                }
              }
            } else {
              return atom
            }
          })
        }
      }

    case MOVE_ATOMS_TO_INDEX: {
      let atoms = []
      const movedAtoms = []

      state.atoms[action.rootKey].forEach((atom, i) => {
        if (action.indices.indexOf(i) !== -1) {
          movedAtoms.push(atom)
        }
      })

      state.atoms[action.rootKey].forEach((atom, i) => {
        if (action.indices.indexOf(i) === -1) {
          if (i === action.targetIndex) {
            if (action.action === 'prepend') {
              atoms = [...atoms, ...movedAtoms, atom]
            } else {
              atoms = [...atoms, atom, ...movedAtoms]
            }
          } else {
            atoms.push(atom)
          }
        }
      })

      return {
        ...state,
        atoms: {
          ...state.atoms,
          [action.rootKey]: atoms
        }
      }
    }

    case UPDATE_FORM_ATOM_ATTACHMENTS: {
      return {
        ...state,
        form: {
          ...state.form,
          atom: {
            ...state.form.atom,
            [action.attachmentKey]: {
              ...state.form.atom[action.attachmentKey],
              ...action.data
            }
          }
        }
      }
    }

    case REMOVE_FORM_ATOM_ATTACHMENT: {
      return {
        ...state,
        form: {
          ...state.form,
          atom: omit(state.form.atom, [action.attachmentKey])
        }
      }
    }

    case SET_FORM_VALIDATION_ERRORS: {
      return {
        ...state,
        form: {
          ...state.form,
          validating: false,
          atoms: state.form.atoms.map((atom, i) => ({
            ...atom,
            ...action.response[i]
          }))
        }
      }
    }

    case UPDATE_FORM_ATOM_ASSOCIATION: {
      return {
        ...state,
        form: {
          ...state.form,
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              return {
                ...atom,
                atom: {
                  ...atom.atom,
                  associations: {
                    ...atom.associations,
                    [action.associationKey]: action.record
                  }
                }
              }
            } else {
              return atom
            }
          })
        }
      }
    }

    default:
      return state
  }
}

export default atomsReducer
