import React from 'react'

import { DROPZONE_TRIGGER_CLASSNAME } from 'containers/Uploader/constants'

export default () => (
  <tr>
    <td colSpan='4' className={`${DROPZONE_TRIGGER_CLASSNAME}-td`}>
      <button colSpan='4' className={DROPZONE_TRIGGER_CLASSNAME} type="button">
        <i className='fa fa-plus-circle'></i>
      </button>
    </td>
  </tr>
)
