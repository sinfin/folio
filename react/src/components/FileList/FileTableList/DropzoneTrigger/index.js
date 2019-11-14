import React from 'react'

import { DROPZONE_TRIGGER_CLASSNAME } from 'containers/Uploader/constants'
import { UploaderContext } from 'containers/Uploader'

class DropzoneTrigger extends React.PureComponent {
  static contextType = UploaderContext

  onClick = () => { this.context() }

  render () {
    return (
      <button
        className={DROPZONE_TRIGGER_CLASSNAME}
        type='button'
        onClick={this.onClick}
      >
        <i className='fa fa-plus-circle' />
      </button>
    )
  }
}

export default DropzoneTrigger
