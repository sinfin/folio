import React from 'react'

class ModalTitleAndUpload extends React.PureComponent {
  triggerUpload = () => {
    window.jQuery('.folio-console-react-modal.show .folio-console-dropzone-trigger').click()
  }

  render () {
    return (
      <div className='modal-header border-bottom-0 pr-5'>
        <h3 className='mr-g modal-title'>
          {this.props.filesKey === 'documents' ? window.FolioConsole.translations.selectDocument : window.FolioConsole.translations.selectImage}
        </h3>

        <button
          className='btn btn-success my-n2 ml-auto'
          type='button'
          onClick={this.triggerUpload}
        >
          <i className='fa fa-plus' />
          {window.FolioConsole.translations.add}
        </button>
      </div>
    )
  }
}

export default ModalTitleAndUpload
