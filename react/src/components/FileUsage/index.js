import React from 'react'

import FileUsageList from './FileUsageList'

function FileUsage ({ filePlacements, changeFilePlacementsPage }) {
  return (
    <React.Fragment>
      <h4 className='mt-0'>{window.FolioConsole.translations.usage}</h4>

      <FileUsageList filePlacements={filePlacements} changeFilePlacementsPage={changeFilePlacementsPage} />
    </React.Fragment>
  )
}

export default FileUsage
