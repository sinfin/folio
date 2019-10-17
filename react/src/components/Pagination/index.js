import React from 'react'
import { Pagination, PaginationItem, PaginationLink } from 'reactstrap'

const makeOnClick = (number, changeFilesPage) => (e) => {
  e.preventDefault()
  e.stopPropagation()
  changeFilesPage(number)
}

function PaginationComponent ({ changeFilesPage, pagination }) {
  const active = pagination.page
  const min = 1
  const max = pagination.pages
  const next = Math.min(max, active + 1)
  const prev = Math.max(min, active - 1)
  const numbers = [min]

  for (let i = active - 3; i < active + 3; i++) {
    if (i > min && i < max && numbers.indexOf(i) === -1) {
      if ((i === active - 3) && i > min + 1) {
        numbers.push('a')
      }

      numbers.push(i)

      if ((i === active + 2) && i + 1 < max) {
        numbers.push('b')
      }
    }
  }

  if (numbers.indexOf(max) === -1) {
    numbers.push(max)
  }

  return (
    <div className='f-c-pagination'>
      <div className='pagy-bootstrap-nav pagination'>
        <Pagination>
          <PaginationItem disabled={prev === active}>
            <PaginationLink href={`#${prev}`} onClick={makeOnClick(prev, changeFilesPage)}>{window.FolioConsole.translations['paginationPrev']}</PaginationLink>
          </PaginationItem>

          {numbers.map((number) => (
            <PaginationItem key={number} active={number === active}>
              {number === 'a' || number === 'b' ? (
                <PaginationLink style={{ pointerEvents: 'none' }}>...</PaginationLink>
              ) : (
                <PaginationLink href={`#${number}`} onClick={makeOnClick(number, changeFilesPage)}>{number}</PaginationLink>
              )}
            </PaginationItem>
          ))}

          <PaginationItem disabled={next === active}>
            <PaginationLink href={`#${next}`} onClick={makeOnClick(next, changeFilesPage)}>{window.FolioConsole.translations['paginationNext']}</PaginationLink>
          </PaginationItem>
        </Pagination>
      </div>
    </div>
  )
}

export default PaginationComponent
