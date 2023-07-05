import React from 'react'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

class ModalTitleAndUpload extends React.PureComponent {
  triggerUpload = () => {
    window.jQuery('.f-c-r-modal.show .f-c-r-dropzone-trigger').click()
  }

  render () {
    return (
      <div className='modal-header border-bottom-0 pr-5'>
        <h3 className='modal-title'>
          {this.props.fileTypeIsImage ? window.FolioConsole.translations.selectImage : window.FolioConsole.translations.selectDocument }
        </h3>

        <FolioConsoleUiButton
          class='my-n2 ml-auto'
          onClick={this.triggerUpload}
          icon='plus'
          variant='success'
          label={window.FolioConsole.translations.add}
        />
      </div>
    )
  }
}

export default ModalTitleAndUpload
