import React from 'react'
import { connect } from 'react-redux'

import {
  addAtomToForm,
  atomsSelector,
  atomTypesSelector,
  createContentlessAtom,
  newAtoms,
  editAtoms,
  removeAtoms,
  validateAndSaveFormAtom,
  closeFormAtom,
  moveAtomsToIndex,
  updateFormAtomType,
  updateFormAtomValue,
  updateFormAtomAttachments,
  removeFormAtomAttachment,
  updateFormAtomAssociation,
  moveFormAtom,
  removeFormAtom,
  validateAndSubmitGlobalForm,
  refreshAtomPreviews
} from 'ducks/atoms'
import { openFileModal } from 'ducks/fileModal'
import AtomForm from 'components/AtomForm'
import SerializedAtoms from 'components/SerializedAtoms'
import { confirm } from 'utils/confirmed'

import { FILE_TRIGGER_EVENT } from './constants'

class Atoms extends React.PureComponent {
  constructor (props) {
    super(props)
    const $ = window.jQuery
    if (!$) return
    $(window).on('message', this.receiveMessage)
    $(document).on(FILE_TRIGGER_EVENT, (e, data) => { this.handleFileTrigger(data) })
  }

  componentWillUnmount () {
    const $ = window.jQuery
    if (!$) return
    $(document).off(FILE_TRIGGER_EVENT)
  }

  receiveMessage = (jqueryEvent) => {
    const { data, origin } = jqueryEvent.originalEvent
    if (origin === window.origin) {
      switch (data.type) {
        case 'newAtoms': {
          if (data.contentable) {
            this.props.dispatch(newAtoms(data.rootKey, data.action, data.indices, data.atomType))
          } else {
            this.props.dispatch(createContentlessAtom(data.rootKey, data.action, data.indices, data.atomType))
          }
          break
        }
        case 'editAtoms': {
          this.props.dispatch(editAtoms(data.rootKey, data.indices))
          break
        }
        case 'moveAtomsToIndex': {
          this.props.dispatch(moveAtomsToIndex(data.rootKey, data.indices, data.targetIndex, data.action))
          break
        }
        case 'removeAtoms': {
          this.props.dispatch(removeAtoms(data.rootKey, data.indices))
          break
        }
        case 'closeForm': {
          this.confirmedDirtyClose()
          break
        }
        case 'refreshPreview': {
          this.refreshPreview()
          break
        }
        default:
          // do nothing
      }
    }
  }

  confirmedDirtyClose = () => {
    if (!this.props.atoms.form.dirty || window.confirm(window.FolioConsole.translations.cancelChanges)) {
      this.props.dispatch(closeFormAtom())
    }
  }

  validateAndSaveFormAtom = () => {
    this.props.dispatch(validateAndSaveFormAtom())
  }

  removeFormAtomAttachment = (index, attachmentKey) => {
    if (confirm()) {
      this.props.dispatch(removeFormAtomAttachment(index, attachmentKey))
    }
  }

  refreshPreview = () => {
    this.props.dispatch(refreshAtomPreviews())
  }

  handleFileTrigger ({ attachmentKey, data, index }) {
    this.props.dispatch(updateFormAtomAttachments(index, attachmentKey, data))
  }

  render () {
    const { atoms, destroyedIds, form, namespace, structures } = this.props.atoms

    return (
      <React.Fragment>
        {Object.keys(atoms).map((key) => (
          <SerializedAtoms
            key={key}
            atoms={atoms[key]}
            namespace={`${namespace}[${key}_attributes]`}
            destroyedIds={destroyedIds[key]}
          />
        ))}

        {form.rootKey && (
          <AtomForm
            form={form}
            index={form.index}
            namespace={`${namespace}[${form.rootKey}_attributes]`}
            rootKey={form.rootKey}
            saveFormAtoms={this.validateAndSaveFormAtom}
            closeFormAtom={this.confirmedDirtyClose}
            updateFormAtomType={(newType, values) => this.props.dispatch(updateFormAtomType(newType, values))}
            updateFormAtomValue={(index, key, value) => this.props.dispatch(updateFormAtomValue(index, key, value))}
            updateFormAtomAssociation={(index, key, record) => this.props.dispatch(updateFormAtomAssociation(index, key, record))}
            removeFormAtomAttachment={this.removeFormAtomAttachment}
            atomTypes={this.props.atomTypes}
            structures={structures}
            addAtom={(type) => this.props.dispatch(addAtomToForm(type))}
            moveFormAtom={(from, to) => this.props.dispatch(moveFormAtom(from, to))}
            removeFormAtom={(index) => this.props.dispatch(removeFormAtom(index))}
            validateAndSubmitGlobalForm={() => this.props.dispatch(validateAndSubmitGlobalForm())}
            openFileModal={(fileType, filesUrl, file) => this.props.dispatch(openFileModal(fileType, filesUrl, file))}
          />
        )}
      </React.Fragment>
    )
  }
}

const mapStateToProps = (state) => ({
  atoms: atomsSelector(state),
  atomTypes: atomTypesSelector(state),
  state: state
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export { Atoms }
export default connect(mapStateToProps, mapDispatchToProps)(Atoms)
