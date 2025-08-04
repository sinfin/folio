import * as React from "react"

export const CloseIcon = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="16"
        height="16"
        className={className}
        viewBox="0 0 16 16"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        {...props}
      >
        <path d="M12.6666 4.27301L11.7266 3.33301L7.99992 7.05967L4.27325 3.33301L3.33325 4.27301L7.05992 7.99967L3.33325 11.7263L4.27325 12.6663L7.99992 8.93967L11.7266 12.6663L12.6666 11.7263L8.93992 7.99967L12.6666 4.27301Z" fill="currentColor"/>
      </svg>
    )
  }
)

CloseIcon.displayName = "CloseIcon"
