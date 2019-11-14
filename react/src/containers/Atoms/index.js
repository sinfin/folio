import React from 'react'
import { connect } from 'react-redux'

import {
  atomsSelector,
  atomTypesSelector,
  newAtom,
  editAtom,
  removeAtom,
  validateAndSaveFormAtom,
  closeFormAtom,
  moveAtomToIndex,
  updateFormAtomType,
  updateFormAtomValue,
  updateFormAtomAttachments,
  removeFormAtomAttachment,
  updateFormAtomAssociation
} from 'ducks/atoms'
import { makeFilePlacementsSelector } from 'ducks/filePlacements'
import AtomForm from 'components/AtomForm'
import SerializedAtoms from 'components/SerializedAtoms'
import { confirm } from 'utils/confirmed'
import fileTypeToKey from 'utils/fileTypeToKey'

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
        case 'newAtom':
          this.props.dispatch(newAtom(data.rootKey, data.index, data.atomType))
          break
        case 'editAtom':
          this.props.dispatch(editAtom(data.rootKey, data.index))
          break
        case 'moveAtomToIndex':
          this.props.dispatch(moveAtomToIndex(data.rootKey, data.index, data.targetIndex))
          break
        case 'removeAtom':
          this.props.dispatch(removeAtom(data.rootKey, data.index))
          break
        case 'closeForm': {
          this.confirmedDirtyClose()
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
    const filePlacementsAttributes = {}
    this.props.atoms.form.atom.meta.attachments.forEach((attachmentType) => {
      if (!attachmentType.plural) return
      const filesKey = fileTypeToKey(attachmentType.file_type)
      const selector = makeFilePlacementsSelector(filesKey)
      const filePlacements = selector(this.props.state)
      filePlacementsAttributes[attachmentType.key] = [
        ...filePlacements.selected,
        ...filePlacements.deleted.map((fp) => ({ ...fp, _destroy: true }))
      ]
    })
    this.props.dispatch(validateAndSaveFormAtom(filePlacementsAttributes))
  }

  removeFormAtomAttachment = (attachmentKey) => {
    if (confirm()) {
      this.props.dispatch(removeFormAtomAttachment(attachmentKey))
    }
  }

  handleFileTrigger ({ attachmentKey, data }) {
    this.props.dispatch(updateFormAtomAttachments(attachmentKey, data))
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
            atom={form.atom}
            index={form.index}
            namespace={`${namespace}[${form.rootKey}_attributes]`}
            rootKey={form.rootKey}
            saveFormAtom={this.validateAndSaveFormAtom}
            closeFormAtom={this.confirmedDirtyClose}
            updateFormAtomType={(newType, values) => this.props.dispatch(updateFormAtomType(newType, values))}
            updateFormAtomValue={(key, value) => this.props.dispatch(updateFormAtomValue(key, value))}
            updateFormAtomAssociation={(key, record) => this.props.dispatch(updateFormAtomAssociation(key, record))}
            removeFormAtomAttachment={this.removeFormAtomAttachment}
            atomTypes={this.props.atomTypes}
            structures={structures}
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
