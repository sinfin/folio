import React from 'react'
import { connect } from 'react-redux'

import {
  atomsSelector,
  atomTypesSelector,
  editAtom,
  removeAtom,
  saveFormAtom,
  closeFormAtom,
  moveAtomToIndex,
  updateFormAtomType,
  updateFormAtomValue,
  updateFormAtomAttachments,
  removeFormAtomAttachment
} from 'ducks/atoms'
import AtomForm from 'components/AtomForm'
import SerializedAtoms from 'components/SerializedAtoms'
import { confirm } from 'utils/confirmed'

import { FILE_TRIGGER_EVENT } from './constants'

class Atoms extends React.PureComponent {
  componentDidMount () {
    window.addEventListener('message', this.receiveMessage, false)
    const $ = window.jQuery
    if (!$) return
    $(document).on(FILE_TRIGGER_EVENT, (e, data) => { this.handleFileTrigger(data) })
  }

  componentWillUnmount () {
    const $ = window.jQuery
    if (!$) return
    $(document).off(FILE_TRIGGER_EVENT)
  }

  receiveMessage = (e) => {
    if (e.origin !== window.origin) return
    switch (e.data.type) {
      case 'editAtom':
        return this.props.dispatch(editAtom(e.data.rootKey, e.data.index))
      case 'moveAtomToIndex':
        return this.props.dispatch(moveAtomToIndex(e.data.rootKey, e.data.index, e.data.targetIndex))

      case 'removeAtom':
        return this.props.dispatch(removeAtom(e.data.rootKey, e.data.index))
      default: {}
    }
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
      <div>
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
            atom={form.atom}
            index={form.index}
            namespace={`${namespace}[${form.rootKey}_attributes]`}
            rootKey={form.rootKey}
            saveFormAtom={() => this.props.dispatch(saveFormAtom())}
            closeFormAtom={() => this.props.dispatch(closeFormAtom())}
            updateFormAtomType={(newType, values) => this.props.dispatch(updateFormAtomType(newType, values))}
            updateFormAtomValue={(key, value) => this.props.dispatch(updateFormAtomValue(key, value))}
            removeFormAtomAttachment={this.removeFormAtomAttachment}
            atomTypes={this.props.atomTypes}
            structures={structures}
          />
        )}
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  atoms: atomsSelector(state),
  atomTypes: atomTypesSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export { Atoms }
export default connect(mapStateToProps, mapDispatchToProps)(Atoms)
