import React from 'react'

import { DROPZONE_TRIGGER_CLASSNAME } from 'containers/Uploader/constants'

export default ({ colSpan }) => (
  <button className={DROPZONE_TRIGGER_CLASSNAME} type='button'>
    <i className='fa fa-plus-circle'></i>
  </button>
)
