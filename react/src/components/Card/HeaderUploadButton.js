import React from 'react'

import { UploaderContext } from 'containers/Uploader'

class HeaderUploadButton extends React.PureComponent {
  static contextType = UploaderContext

  onClick = () => { this.context() }

  render () {
    return (
      <div className='card-header__button'>
        <button type='button' className='btn btn-success card-header__button-btn' onClick={this.onClick}>
          <i className='fa fa-plus' />
          {window.FolioConsole.translations.add}
        </button>
      </div>
    )
  }
}

export default HeaderUploadButton
