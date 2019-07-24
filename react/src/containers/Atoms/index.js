import React from 'react'
import { connect } from 'react-redux'

import {
  atomsSelector,
  updateAtomValue,
} from 'ducks/atoms'
import AtomForm from 'components/AtomForm'

class Atoms extends React.PureComponent {
  onChange ({ rootKey, index, key, value }) {
    this.props.dispatch(updateAtomValue(rootKey, index, key, value))
  }

  render () {
    const { atoms, namespace } = this.props.atoms

    return (
      <div className='row'>
        {Object.keys(atoms).map((key) => (
          <div className='col-lg' key={key}>
            {atoms[key].map((atom, i) => (
              <AtomForm
                key={atom.id}
                atom={atom}
                index={i}
                namespace={`${namespace}[${key}_attributes]`}
                rootKey={key}
                onChange={this.onChange}
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
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Atoms)
