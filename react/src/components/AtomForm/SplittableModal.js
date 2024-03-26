import React from 'react'
import { Button, Input } from 'reactstrap'
import { without } from 'lodash'

import FolioUiIcon from 'components/FolioUiIcon'

import SplittableModalPartsWrap from './styled/SplittableModalPartsWrap'
import SplittableModalPart from './styled/SplittableModalPart'
import SplittableModalDivider from './styled/SplittableModalDivider'

class SplittableModal extends React.PureComponent {
  state = { splitIndices: [] }

  updateIndex (index) {
    if (this.state.splitIndices.indexOf(index) === -1) {
      this.setState({ splitIndices: [...this.state.splitIndices, index] })
    } else {
      this.setState({ splitIndices: without(this.state.splitIndices, index) })
    }
  }

  render () {
    return (
      <div className='modal-content'>
        <div className='modal-header'>
          <h3 className='modal-title'>{window.FolioConsole.translations.atomSplittingTitle}</h3>

          <button class='f-c-modal__close' type='button' onClick={this.props.cancel}>
            <FolioUiIcon name='close' class='f-c-modal__close-icon' />
          </button>
        </div>

        <div className='modal-body'>
          <p className='mb-2'>{window.FolioConsole.translations.atomSplittingText}</p>

          <SplittableModalPartsWrap>
            {this.props.splittable.parts.map((part, index) => (
              <React.Fragment key={index}>
                {index === 0 ? null : (
                  <SplittableModalDivider
                    checked={this.state.splitIndices.indexOf(index) !== -1}
                    onClick={() => { this.updateIndex(index) }}
                  >
                    <Input
                      type='checkbox'
                      checked={this.state.splitIndices.indexOf(index) !== -1}
                      readOnly
                    />
                  </SplittableModalDivider>
                )}

                <SplittableModalPart dangerouslySetInnerHTML={{ __html: part }} />
              </React.Fragment>
            ))}
          </SplittableModalPartsWrap>
        </div>

        <div className='modal-footer'>
          <Button color='secondary' outline onClick={this.props.cancel}>
            {window.FolioConsole.translations.cancel}
          </Button>

          <Button color='dark' onClick={() => { this.props.save(this.state.splitIndices) }}>
            {window.FolioConsole.translations.atomSplittingSubmit}
          </Button>
        </div>
      </div>
    )
  }
}

export default SplittableModal
