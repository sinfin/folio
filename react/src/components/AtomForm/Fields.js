import React from 'react'

import Field from './Field'

export default function Fields ({ atom, index, onChange, onValueChange, rootAtoms, startSplittingAtom }) {
  return (
    <React.Fragment>
      {Object.keys(atom.record.meta.structure).map((field) => (
        <Field
          atom={atom}
          field={field}
          key={field}
          index={index}
          onChange={onChange}
          onValueChange={onValueChange}
          rootAtoms={rootAtoms}
          startSplittingAtom={startSplittingAtom}
        />
      ))}
    </React.Fragment>
  )
}
