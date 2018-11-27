import React from 'react'
import { forceCheck } from 'react-lazyload'

function ModalScroll ({ children, fixed }) {
  return (
    <div className='folio-console-modal__scroll-wrap'>
      {fixed && (
        <div className='folio-console-modal__scroll-fixed'>
          {fixed}
        </div>
      )}

      <div className='folio-console-modal__scroll-inner' onScroll={forceCheck}>
        {children}
      </div>
    </div>
  )
}

export default ModalScroll
