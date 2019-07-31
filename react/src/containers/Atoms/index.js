import React from 'react'
import { connect } from 'react-redux'

import {
  atomsSelector,
  atomTypesSelector,
  editAtom,
  removeAtom,
  saveFormAtom,
  closeFormAtom,
  updateFormAtomType,
  updateFormAtomValue
} from 'ducks/atoms'
import AtomForm from 'components/AtomForm'
import SerializedAtoms from 'components/SerializedAtoms'

class Atoms extends React.PureComponent {
  componentDidMount () {
    window.addEventListener('message', this.receiveMessage, false)
  }

  receiveMessage = (e) => {
    if (e.origin !== window.origin) return
    switch (e.data.type) {
      case 'editAtom':
        return this.props.dispatch(editAtom(e.data.rootKey, e.data.index))
      case 'removeAtom':
        return this.props.dispatch(removeAtom(e.data.rootKey, e.data.index))
      default: {}
    }
  }

  render () {
    const { atoms, form, namespace, structures } = this.props.atoms

    return (
      <div>
        {Object.keys(atoms).map((key) => (
          <SerializedAtoms
            key={key}
            atoms={atoms[key]}
            namespace={`${namespace}[${key}_attributes]`}
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
