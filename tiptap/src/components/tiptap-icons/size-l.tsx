import * as React from "react"

export const SizeLIcon = React.memo(
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
        <path d="M9 7V17H15V15H11V7H9Z" fill="currentColor"/>
      </svg>
    )
  }
)

SizeLIcon.displayName = "SizeLIcon"
