import React from 'react'
import { Input } from 'reactstrap'

import InputWithSearchIconWrap from './styled/InputWithSearchIconWrap'

export default function InputWithSearchIcon (props) {
  return (
    <InputWithSearchIconWrap>
      <Input {...props} />
      <span className='mi'>search</span>
    </InputWithSearchIconWrap>
  )
}
