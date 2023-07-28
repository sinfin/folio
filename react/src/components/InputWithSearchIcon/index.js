import React from 'react'
import { Input } from 'reactstrap'

import FolioUiIcon from 'components/FolioUiIcon'
import InputWithSearchIconWrap from './styled/InputWithSearchIconWrap'
import IconWrap from './styled/IconWrap'

export default function InputWithSearchIcon (props) {
  return (
    <InputWithSearchIconWrap>
      <Input {...props} />

      <IconWrap>
        <FolioUiIcon name='magnify' />
      </IconWrap>
    </InputWithSearchIconWrap>
  )
}
