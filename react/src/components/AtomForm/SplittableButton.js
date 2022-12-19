import React from 'react'
import { Button } from 'reactstrap'

import AtomFormSplittableButtonWrap from './styled/AtomFormSplittableButtonWrap'

export default function SplittableButton ({ startSplittingAtom }) {
  return (
    <AtomFormSplittableButtonWrap>
      <Button color='secondary' onClick={startSplittingAtom} className='btn-mini'>
        <span className='fa fa-unlink' />
        {window.FolioConsole.translations.startSplittingAtom}
      </Button>
    </AtomFormSplittableButtonWrap>
  )
}
