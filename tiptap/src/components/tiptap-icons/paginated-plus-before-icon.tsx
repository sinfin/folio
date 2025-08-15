import * as React from "react"

export const PaginatedPlusBeforeIcon = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="24"
        height="24"
        className={className}
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        {...props}
      >
        <path d="M11 10H13V7H16V5H13V2H11V5H8V7H11V10Z" fill="currentColor"/>
        <path d="M21.4142 13.5858C21.7893 13.9609 22 14.4696 22 15V21H20V15H4V21H2V15C2 14.4696 2.21071 13.9609 2.58579 13.5858C2.96086 13.2107 3.46957 13 4 13H20C20.5304 13 21.0391 13.2107 21.4142 13.5858Z" fill="currentColor"/>
      </svg>
    )
  }
)

PaginatedPlusBeforeIcon.displayName = "PaginatedPlusBeforeIcon"
