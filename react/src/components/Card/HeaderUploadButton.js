import React from 'react'

import { UploaderContext } from 'containers/Uploader'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

class HeaderUploadButton extends React.PureComponent {
  static contextType = UploaderContext

  onClick = () => { this.context() }

  render () {
    return (
      <div className='card-header__button'>
        <FolioConsoleUiButton
          onClick={this.onClick}
          variant='success'
          icon='plus'
          label={window.FolioConsole.translations.add}
        />
      </div>
    )
  }
}

export default HeaderUploadButton
