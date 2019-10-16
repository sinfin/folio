import React from 'react'

import StyledLoader from './styled/StyledLoader'

function Loader ({ standalone }) {
  return (
    <StyledLoader className='folio-loader' standalone={standalone} />
  )
}

export default Loader
