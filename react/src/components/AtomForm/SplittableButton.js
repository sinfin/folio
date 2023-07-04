import React from 'react'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import AtomFormSplittableButtonWrap from './styled/AtomFormSplittableButtonWrap'

export default function SplittableButton ({ startSplittingAtom }) {
  return (
    <AtomFormSplittableButtonWrap>
      <FolioConsoleUiButton
        variant='secondary'
        onClick={startSplittingAtom}
        icon='link'
        label={window.FolioConsole.translations.startSplittingAtom}
      />
    </AtomFormSplittableButtonWrap>
  )
}
