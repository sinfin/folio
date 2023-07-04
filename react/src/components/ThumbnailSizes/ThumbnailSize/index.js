import React from 'react'

import Scroller from './Scroller'

import { RawPicture } from 'components/Picture'
import FolioUiIcon from 'components/FolioUiIcon'
import FolioUiWithIcon from 'components/FolioUiWithIcon'

class ThumbnailSize extends React.Component {
  constructor (props) {
    super(props)
    this.state = { editing: false }
  }

  save = (offset) => {
    this.props.updateThumbnail(this.props.thumbKey, offset)
    this.close()
  }

  close = () => {
    this.setState({ ...this.state, editing: false })
  }

  destroy = () => {
    if (window.confirm(window.FolioConsole.translations.removePrompt)) {
      this.props.destroyThumbnail(this.props.thumbKey, this.props.thumb)
    }
  }

  render () {
    const { thumb, thumbKey } = this.props
    const editable = thumbKey.indexOf('#') !== -1

    const height = 140
    const width = thumb.width * height / thumb.height

    return (
      <div className='mr-g my-h position-relative' style={{ width: width }}>
        {this.state.editing ? (
          <Scroller
            file={this.props.file}
            thumb={this.props.thumb}
            thumbKey={thumbKey}
            height={height}
            width={width}
            close={this.close}
            save={this.save}
          />
        ) : (
          <div>
            <div style={{ height: height, width: width, backgroundColor: '#495057' }}>
              {thumb._saving ? null : <RawPicture src={this.props.thumb.url} webpSrc={this.props.thumb.webp_url} imageStyle={{ height: height, width: width }} alt={thumbKey} />}
            </div>

            <div className='mt-2 pt-1 small d-flex align-items-center'>
              {thumbKey}

              <div className='pl-3 ml-auto fa cursor-pointer' onClick={this.destroy}>
                <FolioUiIcon name='delete' />
              </div>
            </div>

            {editable && (
              <FolioUiWithIcon
                class='cursor-pointer text-semi-muted mt-1 text-nowrap'
                icon='crop'
                iconHeight={16}
                onClick={() => { this.setState({ ...this.state, editing: true }) }}
              >
                {window.FolioConsole.translations.editOffset}
              </FolioUiWithIcon>
            )}
          </div>
        )}

        {thumb._saving && <div className='folio-loader' />}
      </div>
    )
  }
}

export default ThumbnailSize
