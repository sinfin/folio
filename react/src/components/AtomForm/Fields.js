import React from 'react'

import Field from './Field'

export default function Fields ({ atom, index, onChange, onValueChange, startSplittingAtom }) {
  const atomKey = atom.record.id || atom.record.lodashId
  
  return (
    <React.Fragment>
      {Object.keys(atom.record.meta.structure).map((field) => (
        <Field
          atom={atom}
          field={field}
          key={`${atomKey}-${field}`}
          index={index}
          onChange={onChange}
          onValueChange={onValueChange}
          startSplittingAtom={startSplittingAtom}
        />
      ))}
    </React.Fragment>
  )
}
