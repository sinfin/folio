import React from 'react'
import { connect } from 'react-redux'
import ReactModal from 'react-modal'

import {
  addAtomToForm,
  atomsSelector,
  atomTypesSelector,
  createContentlessAtom,
  newAtoms,
  editAtoms,
  removeAtoms,
  validateAndSaveFormAtom,
  saveFormAtoms,
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
  refreshAtomPreviews,
  splitFormAtom,
  mergeSplittableAtoms
} from 'ducks/atoms'
import { openFileModal } from 'ducks/fileModal'
import AtomForm from 'components/AtomForm'
import SerializedAtoms from 'components/SerializedAtoms'
import SplittableJoinModal from 'components/SplittableJoinModal'

ReactModal.setAppElement('body')

class Atoms extends React.PureComponent {
  state = { splittable: null }

  constructor (props) {
    super(props)
    const $ = window.jQuery
    if (!$) return
    $(window).on('message', this.receiveMessage)
  }

  onSimpleFormWithAtomsSubmit = (e) => {
    if (this.props.atoms.form.rootKey) {
      e.preventDefault()
      e.stopPropagation()
      this.props.dispatch(validateAndSubmitGlobalForm())
    } else {
      e.target.classList.add('f-c-simple-form-with-atoms--submitting')
    }
  }

  componentDidMount () {
    const form = document.querySelector('.f-c-simple-form-with-atoms')

    if (form) {
      form.addEventListener('submit', this.onSimpleFormWithAtomsSubmit)
    }
  }

  componentWillUnmount () {
    const form = document.querySelector('.f-c-simple-form-with-atoms')

    if (form) {
      form.removeEventListener('submit', this.onSimpleFormWithAtomsSubmit)
    }
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
        case 'splittableJoinAtomsPrompt': {
          this.startSplittable(data)
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

  saveFormAtomsWithoutValidation = () => {
    this.props.dispatch(saveFormAtoms())
  }

  updateFormAtomAttachment = (index, attachmentKey, file) => {
    this.props.dispatch(updateFormAtomAttachments(index, attachmentKey, { file_id: file.id, file }))
  }

  removeFormAtomAttachment = (index, attachmentKey) => {
    this.props.dispatch(removeFormAtomAttachment(index, attachmentKey))
  }

  refreshPreview = () => {
    this.props.dispatch(refreshAtomPreviews())
  }

  getSplittableContent (rootKey, indices, field) {
    let content = ''
    const atoms = this.props.atoms.atoms[rootKey]

    indices.forEach((index) => {
      content += atoms[index].data[field]
    })

    return content
  }

  startSplittable ({ rootKey, indices, field }) {
    this.setState({ ...this.state,
      splittable: {
        rootKey,
        indices,
        field,
        content: this.getSplittableContent(rootKey, indices, field)
      } })
  }

  splittableSave = () => {
    this.props.dispatch(mergeSplittableAtoms(this.state.splittable.rootKey,
      this.state.splittable.indices,
      this.state.splittable.field))
    this.splittableCancel()
  }

  splittableCancel = () => {
    this.setState({ ...this.state, splittable: null })
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
            saveFormAtomsWithoutValidation={this.saveFormAtomsWithoutValidation}
            closeFormAtom={this.confirmedDirtyClose}
            updateFormAtomType={(newType, values) => this.props.dispatch(updateFormAtomType(newType, values))}
            updateFormAtomValue={(index, key, value) => this.props.dispatch(updateFormAtomValue(index, key, value))}
            updateFormAtomAssociation={(index, key, record) => this.props.dispatch(updateFormAtomAssociation(index, key, record))}
            updateFormAtomAttachment={this.updateFormAtomAttachment}
            removeFormAtomAttachment={this.removeFormAtomAttachment}
            atomTypes={this.props.atomTypes}
            structures={structures}
            addAtom={(type) => this.props.dispatch(addAtomToForm(type))}
            moveFormAtom={(from, to) => this.props.dispatch(moveFormAtom(from, to))}
            removeFormAtom={(index) => this.props.dispatch(removeFormAtom(index))}
            openFileModal={(fileType, filesUrl, file) => this.props.dispatch(openFileModal(fileType, filesUrl, file))}
            splitFormAtom={(field, parts) => this.props.dispatch(splitFormAtom(field, parts))}
          />
        )}

        <ReactModal
          isOpen={!!this.state.splittable}
          onRequestClose={this.splittableCancel}
          className='ReactModal ReactModal--AtomsSplittableJoin'
        >
          {this.state.splittable ? (
            <SplittableJoinModal
              content={this.state.splittable.content}
              save={this.splittableSave}
              cancel={this.splittableCancel}
            />
          ) : null}
        </ReactModal>
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
