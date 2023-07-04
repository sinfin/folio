import React from 'react'

import { DROPZONE_TRIGGER_CLASSNAME } from 'containers/Uploader/constants'
import { UploaderContext } from 'containers/Uploader'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

class DropzoneTrigger extends React.PureComponent {
  static contextType = UploaderContext

  onClick = () => { this.context() }

  render () {
    return (
      <FolioConsoleUiButton
        class={DROPZONE_TRIGGER_CLASSNAME}
        onClick={this.onClick}
        icon='plus'
      />
    )
  }
}

export default DropzoneTrigger
