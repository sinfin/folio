import React from 'react'

import FilePlacementSortableList from './FilePlacementSortableList';

const FilePlacementList = (props) => (
  <FilePlacementSortableList
    axis='xy'
    distance={5}
    {...props}
  />
)

export default FilePlacementList
