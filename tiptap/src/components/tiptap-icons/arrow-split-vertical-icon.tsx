import * as React from "react"

export const ArrowSplitVerticalIcon = React.memo(
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
        <path d="M18 16V13H15V22H13V2H15V11H18V8L22 12L18 16ZM2 12L6 16V13H9V22H11V2H9V11H6V8L2 12Z" fill="currentColor"/>
      </svg>
    )
  }
)

ArrowSplitVerticalIcon.displayName = "ArrowSplitVerticalIcon"
