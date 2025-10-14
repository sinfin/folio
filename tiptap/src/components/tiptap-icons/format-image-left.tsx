import * as React from "react";

export const FormatImageLeft = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="24"
        height="24"
        className={className}
        viewBox="0 -960 960 960"
        xmlns="http://www.w3.org/2000/svg"
        {...props}
      >
        <path
          d="M120-280v-400h400v400H120Zm80-80h240v-240H200v240Zm-80-400v-80h720v80H120Zm480 160v-80h240v80H600Zm0 160v-80h240v80H600Zm0 160v-80h240v80H600ZM120-120v-80h720v80H120Z"
          fill="currentColor"
        />
      </svg>
    );
  },
);

FormatImageLeft.displayName = "FormatImageLeft";
