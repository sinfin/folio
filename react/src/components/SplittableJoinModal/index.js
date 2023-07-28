import React from 'react'
import { Button } from 'reactstrap'

import FolioUiIcon from 'components/FolioUiIcon'
import SplittableModalPartsWrap from '../AtomForm/styled/SplittableModalPartsWrap'

function SplittableJoinModal ({ content, save, cancel }) {
  return (
    <div className='modal-content'>
      <div className='modal-header'>
        <h3 className='modal-title'>{window.FolioConsole.translations.atomSplittableJoinTitle}</h3>

        <button class='f-c-modal__close' type='button' onClick={cancel}>
          <FolioUiIcon name='close' class='f-c-modal__close-icon' />
        </button>
      </div>

      <div className='modal-body'>
        <p className='mb-2'>{window.FolioConsole.translations.atomSplittableJoinText}</p>

        <SplittableModalPartsWrap dangerouslySetInnerHTML={{ __html: content }} />
      </div>

      <div className='modal-footer'>
        <Button color='secondary' outline onClick={cancel}>
          {window.FolioConsole.translations.cancel}
        </Button>

        <Button color='dark' onClick={save}>
          {window.FolioConsole.translations.atomSplittableJoinSubmit}
        </Button>
      </div>
    </div>
  )
}

export default SplittableJoinModal
