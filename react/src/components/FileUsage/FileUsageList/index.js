import React from 'react'

import Pagination from 'components/Pagination'
import Loader from 'components/Loader'

function FileUsageList ({ filePlacements, changeFilePlacementsPage }) {
  if (filePlacements.loading) return <Loader standalone={300} />
  if (filePlacements.records.length === 0) {
    return <p className='mt-h small'>{window.FolioConsole.translations.paginationEmpty}</p>
  }

  return (
    <React.Fragment>
      <ul className='list-unstyled small mt-h mb-n4'>
        {filePlacements.records.map((filePlacement) => (
          <li key={filePlacement.id}>
            {filePlacement.attributes.url ? (
              <a href={filePlacement.attributes.url} target='_blank' rel='noopener noreferrer'>{filePlacement.attributes.label || '---'}</a>
            ) : (filePlacement.attributes.label || '---')}
          </li>
        ))}
      </ul>

      <Pagination
        pagination={filePlacements.pagination}
        changePage={changeFilePlacementsPage}
      />
    </React.Fragment>
  )
}

export default FileUsageList
