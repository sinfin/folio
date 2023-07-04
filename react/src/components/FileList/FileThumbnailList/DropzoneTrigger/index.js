import React from 'react'

import { DROPZONE_TRIGGER_CLASSNAME } from 'containers/Uploader/constants'
import { UploaderContext } from 'containers/Uploader'
import FolioUiIcon from 'components/FolioUiIcon'

class DropzoneTrigger extends React.PureComponent {
  static contextType = UploaderContext

  onClick = () => { this.context() }

  render () {
    return (
      <div
        className={`f-c-file-list__dropzone-trigger ${DROPZONE_TRIGGER_CLASSNAME}`}
        onClick={this.onClick}
      >
        <FolioUiIcon name='plus_circle' />
      </div>
    )
  }
}

export default DropzoneTrigger
