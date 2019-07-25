import React from 'react'
import { connect } from 'react-redux'
import { isEqual } from 'lodash'

import {
  atomsSelector,
  atomTypesSelector,
  updateAtomValue,
  updateAtomType
} from 'ducks/atoms'
import AtomForm from 'components/AtomForm'

class Atoms extends React.PureComponent {
  onChange = ({ rootKey, index, key, value }) => {
    this.props.dispatch(updateAtomValue(rootKey, index, key, value))
  }

  onTypeChange = ({ rootKey, index, newType }) => {
    const atom = this.props.atoms.atoms[rootKey][index]
    const newStructure = this.props.atoms.structures[newType].structure
    const oldStructure = atom.meta.structure
    const values = {}
    Object.keys(newStructure).forEach((key) => {
      if (isEqual(newStructure[key], oldStructure[key])) {
        values[key] = atom.data[key]
      }
    })
    this.props.dispatch(updateAtomType(rootKey, index, newType, values))
  }

  render () {
    const { atoms, namespace } = this.props.atoms

    return (
      <div className='row'>
        {Object.keys(atoms).map((key) => (
          <div className='col-lg folio-console--compact' key={key}>
            {atoms[key].map((atom, i) => (
              <AtomForm
                key={atom.id}
                atom={atom}
                index={i}
                namespace={`${namespace}[${key}_attributes]`}
                rootKey={key}
                onChange={this.onChange}
                onTypeChange={this.onTypeChange}
                atomTypes={this.props.atomTypes}
              />
            ))}
          </div>
        ))}
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

export default connect(mapStateToProps, mapDispatchToProps)(Atoms)
