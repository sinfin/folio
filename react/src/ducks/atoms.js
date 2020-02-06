import { mapValues, sortBy, omit, uniqueId } from 'lodash'
import { takeEvery, takeLatest, call, select, put } from 'redux-saga/effects'

import { apiHtmlPost, apiPost } from 'utils/api'
import arrayMove from 'utils/arrayMove'

import { combineAtoms } from 'ducks/utils/atoms'

// Constants

const SET_ATOMS_DATA = 'atoms/SET_ATOMS_DATA'
const NEW_ATOMS = 'atoms/NEW_ATOMS'
const CREATE_CONTENTLESS_ATOM = 'atoms/CREATE_CONTENTLESS_ATOM'
const EDIT_ATOMS = 'atoms/EDIT_ATOMS'
const REMOVE_ATOMS = 'atoms/REMOVE_ATOMS'
const VALIDATE_AND_SAVE_FORM_ATOMS = 'atoms/VALIDATE_AND_SAVE_FORM_ATOMS'
const VALIDATE_AND_SUBMIT_GLOBAL_FORM = 'atoms/VALIDATE_AND_SUBMIT_GLOBAL_FORM'
const SAVE_FORM_ATOMS = 'atoms/SAVE_FORM_ATOMS'
const CLOSE_FORM_ATOM = 'atoms/CLOSE_FORM_ATOM'
const UPDATE_FORM_ATOM_TYPE = 'atoms/UPDATE_FORM_ATOM_TYPE'
const UPDATE_FORM_ATOM_VALUE = 'atoms/UPDATE_FORM_ATOM_VALUE'
const MOVE_ATOMS_TO_INDEX = 'atoms/MOVE_ATOMS_TO_INDEX'
const UPDATE_FORM_ATOM_ATTACHMENTS = 'atoms/UPDATE_FORM_ATOM_ATTACHMENTS'
const REMOVE_FORM_ATOM_ATTACHMENT = 'atoms/REMOVE_FORM_ATOM_ATTACHMENT'
const SET_FORM_VALIDATION_ERRORS = 'atoms/SET_FORM_VALIDATION_ERRORS'
const UPDATE_FORM_ATOM_ASSOCIATION = 'atoms/UPDATE_FORM_ATOM_ASSOCIATION'
const ADD_ATOM_TO_FORM = 'atoms/ADD_ATOM_TO_FORM'
const MOVE_FORM_ATOM = 'atoms/MOVE_FORM_ATOM'
const REMOVE_FORM_ATOM = 'atoms/REMOVE_FORM_ATOM'
const ATOM_FORM_PLACEMENTS_SELECT = 'atoms/ATOM_FORM_PLACEMENTS_SELECT'
const ATOM_FORM_PLACEMENTS_UNSELECT = 'atoms/ATOM_FORM_PLACEMENTS_UNSELECT'
const ATOM_FORM_PLACEMENTS_SORT = 'atoms/ATOM_FORM_PLACEMENTS_SORT'
const ATOM_FORM_PLACEMENTS_CHANGE = 'atoms/ATOM_FORM_PLACEMENTS_CHANGE'

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

export function createContentlessAtom (rootKey, action, indices, atomType) {
  return { type: CREATE_CONTENTLESS_ATOM, rootKey, action, indices, atomType }
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

export function validateAndSaveFormAtom () {
  return { type: VALIDATE_AND_SAVE_FORM_ATOMS }
}

export function validateAndSubmitGlobalForm () {
  return { type: VALIDATE_AND_SUBMIT_GLOBAL_FORM }
}

export function saveFormAtoms () {
  return { type: SAVE_FORM_ATOMS }
}

export function updateFormAtomAttachments (index, attachmentKey, data) {
  return { type: UPDATE_FORM_ATOM_ATTACHMENTS, index, attachmentKey, data }
}

export function removeFormAtomAttachment (index, attachmentKey) {
  return { type: REMOVE_FORM_ATOM_ATTACHMENT, index, attachmentKey }
}

export function setFormValidationErrors (response) {
  return { type: SET_FORM_VALIDATION_ERRORS, response }
}

export function updateFormAtomAssociation (index, associationKey, record) {
  return { type: UPDATE_FORM_ATOM_ASSOCIATION, index, associationKey, record }
}

export function addAtomToForm (atomType) {
  return { type: ADD_ATOM_TO_FORM, atomType }
}

export function moveFormAtom (from, to) {
  return { type: MOVE_FORM_ATOM, from, to }
}

export function removeFormAtom (index) {
  return { type: REMOVE_FORM_ATOM, index }
}

export function atomFormPlacementsSelect (index, attachmentKey, file) {
  return { type: ATOM_FORM_PLACEMENTS_SELECT, index, attachmentKey, file }
}

export function atomFormPlacementsUnselect (index, attachmentKey, filePlacement) {
  return { type: ATOM_FORM_PLACEMENTS_UNSELECT, index, attachmentKey, filePlacement }
}

export function atomFormPlacementsSort (index, attachmentKey, oldIndex, newIndex) {
  return { type: ATOM_FORM_PLACEMENTS_SORT, index, attachmentKey, oldIndex, newIndex }
}

export function atomFormPlacementsChange (index, attachmentKey, filePlacement, attribute, value) {
  return { type: ATOM_FORM_PLACEMENTS_CHANGE, index, attachmentKey, filePlacement, attribute, value }
}

export function atomFormPlacementsChangeTitle (index, attachmentKey, filePlacement, title) {
  return atomFormPlacementsChange(index, attachmentKey, filePlacement, 'title', title)
}

export function atomFormPlacementsChangeAlt (index, attachmentKey, filePlacement, alt) {
  return atomFormPlacementsChange(index, attachmentKey, filePlacement, 'alt', alt)
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
  const unsorted = []

  Object.keys(state.atoms.structures).forEach((key) => {
    const str = state.atoms.structures[key]
    if (!str.molecule_secondary) {
      unsorted.push({ key, title: str.title })
    }
  })

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

  return omit(base, ['meta', 'lodashId', 'data'])
}

export const serializedAtomsSelector = (state) => {
  const h = {}
  Object.keys(state.atoms.atoms).forEach((rootKey) => {
    h[`${rootKey}_attributes`] = state.atoms.atoms[rootKey].map((atom) => serializeAtom(state, atom))
  })
  return h
}

export const serializedFormAtomsSelector = (state) => (
  state.atoms.form.atoms.map((atom) => serializeAtom(state, atom.record))
)

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
    takeEvery(SET_ATOMS_DATA, updateAtomPreviews),
    takeEvery(CREATE_CONTENTLESS_ATOM, updateAtomPreviews)
  ]
}

function * showAtomsForm (action) {
  yield window.jQuery('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--editing-atom')
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

function * validateAndSaveFormAtomPerform (action) {
  const serializedForm = yield select(serializedFormAtomsSelector)
  const response = yield (call(apiPost, '/console/atoms/validate', { atoms: serializedForm }))
  let valid = true
  response.forEach((res) => { valid = valid && res.valid })

  if (valid) {
    yield put(saveFormAtoms())
  } else {
    yield put(setFormValidationErrors(response))
  }
}

function * validateAndSaveFormAtomSaga () {
  yield takeEvery(VALIDATE_AND_SAVE_FORM_ATOMS, validateAndSaveFormAtomPerform)
}

function * validateAndSubmitGlobalFormPerform (action) {
  yield validateAndSaveFormAtomPerform()
  const form = yield select(atomsFormSelector)
  if (form.rootKey) {
    window.jQuery('.f-c-form-footer__btn--submit').prop('disabled', false)
  } else {
    window.jQuery('.f-c-simple-form-with-atoms').submit()
  }
}

function * validateAndSubmitGlobalFormSaga () {
  yield takeLatest(VALIDATE_AND_SUBMIT_GLOBAL_FORM, validateAndSubmitGlobalFormPerform)
}

export const atomsSagas = [
  updateAtomPreviewsSaga,
  showAtomsFormSaga,
  hideAtomsFormSaga,
  validateAndSaveFormAtomSaga,
  validateAndSubmitGlobalFormSaga
]

// State

export const DEFAULT_FORM_ATOM_STATE = {
  record: null,
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
      Object.keys(action.data.atoms).forEach((atomsKey) => {
        atoms[atomsKey] = action.data.atoms[atomsKey].map((atom) => {
          return {
            ...atom,
            lodashId: uniqueId('atom_')
          }
        })
      })

      return {
        ...state,
        ...action.data,
        atoms
      }
    }

    case NEW_ATOMS:
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
              record: {
                id: null,
                type: action.atomType,
                data: {},
                lodashId: uniqueId('atom_'),
                meta: state.structures[action.atomType],
                associations: {}
              }
            }
          ]
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
          atoms: atomsByIndicesSelector(state, action.rootKey, action.indices).map((record) => ({
            ...DEFAULT_FORM_ATOM_STATE,
            record
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

    case CREATE_CONTENTLESS_ATOM: {
      const atoms = combineAtoms({
        oldAtoms: state.atoms[action.rootKey],
        newAtoms: [{ id: null, type: action.atomType, lodashId: uniqueId('atom_'), data: {}, associations: {} }],
        edit: false,
        indices: action.indices,
        formAction: action.action
      })

      return {
        ...state,
        atoms: {
          ...state.atoms,
          [action.rootKey]: atoms
        }
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

      const atoms = combineAtoms({
        oldAtoms: state.atoms[state.form.rootKey],
        newAtoms: state.form.atoms.map((atom) => ({ ...omit(atom.record, ['meta']), lodashId: uniqueId('atom_') })),
        edit: state.form.edit,
        indices: state.form.indices,
        formAction: state.form.action
      })

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
        if (atom.record.id) {
          destroyedIds.push(atom.record.id)
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
              record: {
                id: null,
                type: action.newType,
                data: action.values,
                lodashId: uniqueId('atom_'),
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
                record: {
                  ...atom.record,
                  data: {
                    ...atom.record.data,
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
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              return {
                ...atom,
                record: {
                  ...atom.record,
                  [action.attachmentKey]: {
                    ...omit(atom.record[action.attachmentKey], ['_destroy']),
                    ...action.data
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

    case REMOVE_FORM_ATOM_ATTACHMENT: {
      return {
        ...state,
        form: {
          ...state.form,
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              const record = omit(atom.record, [action.attachmentKey])
              if (atom.record[action.attachmentKey] && atom.record[action.attachmentKey].id) {
                record[action.attachmentKey] = {
                  id: atom.record[action.attachmentKey].id,
                  _destroy: true
                }
              }

              return {
                ...atom,
                record
              }
            } else {
              return atom
            }
          })
        }
      }
    }

    case SET_FORM_VALIDATION_ERRORS: {
      return {
        ...state,
        form: {
          ...state.form,
          atoms: state.form.atoms.map((atom, i) => ({
            ...atom,
            ...action.response[i],
            validating: false
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
                record: {
                  ...atom.record,
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

    case ADD_ATOM_TO_FORM:
      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          atoms: [
            ...state.form.atoms,
            {
              ...DEFAULT_FORM_ATOM_STATE,
              record: {
                id: null,
                type: action.atomType,
                data: {},
                lodashId: uniqueId('atom_'),
                meta: state.structures[action.atomType],
                associations: {}
              }
            }
          ]
        }
      }

    case MOVE_FORM_ATOM:
      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          atoms: sortBy(arrayMove(state.form.atoms, action.from, action.to), (a) => !a.record.meta.molecule_singleton)
        }
      }

    case REMOVE_FORM_ATOM: {
      const atoms = []
      const destroyedIds = [...state.form.destroyedIds]

      state.form.atoms.forEach((atom, i) => {
        if (i === action.index) {
          if (atom.record.id) {
            destroyedIds.push(atom.record.id)
          }
        } else {
          atoms.push(atom)
        }
      })

      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          destroyedIds,
          atoms
        }
      }
    }

    case ATOM_FORM_PLACEMENTS_SELECT: {
      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              let placements = []
              let replaced = false

              if (atom.record[action.attachmentKey]) {
                placements = atom.record[action.attachmentKey].map((placement) => {
                  if (placement.file_id === action.file.id) {
                    replaced = true
                    return omit(placement, ['_destroy'])
                  } else {
                    return placement
                  }
                })
              }

              if (!replaced) {
                placements.push({
                  id: null,
                  file_id: action.file.id,
                  file: action.file,
                  selectedAt: Date.now()
                })
              }

              return {
                ...atom,
                record: {
                  ...atom.record,
                  [action.attachmentKey]: placements
                }
              }
            } else {
              return atom
            }
          })
        }
      }
    }

    case ATOM_FORM_PLACEMENTS_UNSELECT: {
      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              const placements = []

              atom.record[action.attachmentKey].forEach((placement) => {
                if (placement.file_id === action.filePlacement.file_id) {
                  if (placement.id) {
                    placements.push({ ...placement, _destroy: true })
                  } else {
                    // remove non-id placement by not pushing it to the array
                  }
                } else {
                  placements.push(placement)
                }
              })

              return {
                ...atom,
                record: {
                  ...atom.record,
                  [action.attachmentKey]: placements
                }
              }
            } else {
              return atom
            }
          })
        }
      }
    }

    case ATOM_FORM_PLACEMENTS_SORT: {
      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              const placements = arrayMove(atom.record[action.attachmentKey], action.oldIndex, action.newIndex)

              return {
                ...atom,
                record: {
                  ...atom.record,
                  [action.attachmentKey]: placements
                }
              }
            } else {
              return atom
            }
          })
        }
      }
    }

    case ATOM_FORM_PLACEMENTS_CHANGE: {
      return {
        ...state,
        form: {
          ...state.form,
          dirty: true,
          atoms: state.form.atoms.map((atom, i) => {
            if (i === action.index) {
              const placements = atom.record[action.attachmentKey].map((placement) => {
                if (placement.file_id === action.filePlacement.file_id) {
                  return { ...placement, [action.attribute]: action.value }
                } else {
                  return placement
                }
              })

              return {
                ...atom,
                record: {
                  ...atom.record,
                  [action.attachmentKey]: placements
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
