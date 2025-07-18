import * as React from "react"

export const AddColumnBefore = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="24"
        height="24"
        className={className}
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        {...props}
      >
        <g transform="rotate(180 12 12)">
          <rect width="10" height="20" x="2" y="2" rx="2" />
          <path d="M21.593 11.998H15.19M18.39 15.201V8.8" />
        </g>
      </svg>
    )
  }
)
AddColumnBefore.displayName = "AddColumnBefore"
