import React from 'react'

import { DROPZONE_TRIGGER_CLASSNAME } from 'containers/Uploader/constants'

export default ({ colSpan }) => (
  <tr>
    <td colSpan={colSpan} className={`${DROPZONE_TRIGGER_CLASSNAME}-td`}>
      <button className={DROPZONE_TRIGGER_CLASSNAME} type='button'>
        <i className='fa fa-plus-circle'></i>
      </button>
    </td>
  </tr>
)
