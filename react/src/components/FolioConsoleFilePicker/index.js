import React from 'react'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

const I18N = {
  cs: {
    addFile: 'Přidat soubor'
  },
  en: {
    addFile: 'Add file'
  }
}

class FolioConsoleFilePicker extends React.PureComponent {
  constructor (props) {
    super(props)
    this.pickerRef = React.createRef()
  }

  handleFileUpdate = (e) => {
    if (e.detail.file) {
      this.props.update(e.detail.file)
    } else {
      this.props.remove()
    }
  }

  componentDidMount () {
    if (this.pickerRef && this.pickerRef.current) {
      this.pickerRef.current.addEventListener('folioConsoleFilePickerInReact/fileUpdate', this.handleFileUpdate)
    }
  }

  componentWillUnmount () {
    this.pickerRef.current.removeEventListener('folioConsoleFilePickerInReact/fileUpdate', this.handleFileUpdate)
  }

  btnLabel () {
    if (this.props.attachmentType.human_type !== 'image') {
      return window.Folio.i18n(I18N, 'addFile')
    }
  }

  render () {
    const data = {
      'data-controller': 'f-c-files-picker',
      'data-action': 'f-c-files-index-modal:selectedFile->f-c-files-picker#onModalSelectedFile',
      'data-f-c-files-picker-file-type-value': this.props.attachmentType.file_type,
      'data-f-c-files-picker-state-value': this.props.file ? 'filled' : 'empty',
      'data-f-c-files-picker-in-react-value': 'true',
      'data-f-c-files-picker-react-file-value': this.props.file ? JSON.stringify(this.props.file) : '{}'
    }

    return (
      <div
        className={`f-c-files-picker form-group f-c-files-picker--as-${this.props.attachmentType.human_type}`}
        ref={this.pickerRef}
        {...data}
      >
        <label className='string optional form-label'>{this.props.attachmentType.label}</label>

        <div className='f-c-files-picker__inner'>
          <div className='f-c-files-picker__content' data-f-c-files-picker-target='content' />

          <div className='f-c-files-picker__btn-wrap'>
            <FolioConsoleUiButton
              class='f-c-files-picker__btn'
              variant='success'
              label={this.btnLabel()}
              icon='plus'
              dataAction='f-c-files-picker#onBtnClick'
            />
          </div>
        </div>

        <span className='folio-loader f-c-files-picker__loader' />
      </div>
    )
  }
}

export default FolioConsoleFilePicker
