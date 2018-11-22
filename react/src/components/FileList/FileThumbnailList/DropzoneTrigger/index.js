import React from 'react'

import { DROPZONE_TRIGGER_CLASSNAME } from 'containers/Uploader/constants'

export default () => (
  <div className={`folio-console-file-list__dropzone-trigger ${DROPZONE_TRIGGER_CLASSNAME}`}>
    <i className='fa fa-plus-circle'></i>
  </div>
)
