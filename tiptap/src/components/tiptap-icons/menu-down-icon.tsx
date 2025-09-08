import * as React from "react"

export const MenuDownIcon = React.memo(
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
        <path d="M7 10L12 15L17 10H7Z" fill="currentColor"/>
      </svg>
    )
  }
)

MenuDownIcon.displayName = "MenuDownIcon"
