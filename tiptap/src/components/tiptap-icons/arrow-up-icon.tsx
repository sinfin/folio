import * as React from "react"

export const ArrowUpIcon = React.memo(
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
        <path d="M13.0001 20H11.0001V8.00003L5.50008 13.5L4.08008 12.08L12.0001 4.16003L19.9201 12.08L18.5001 13.5L13.0001 8.00003V20Z" fill="currentColor"/>
      </svg>
    )
  }
)

ArrowUpIcon.displayName = "ArrowUpIcon"
