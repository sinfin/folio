import * as React from "react";

export const PaginatedPlusAfterIcon = React.memo(
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
        <path
          d="M13 14L11 14L11 17L8 17L8 19L11 19L11 22L13 22L13 19L16 19L16 17L13 17L13 14Z"
          fill="currentColor"
        />
        <path
          d="M2.58579 10.4142C2.21071 10.0391 2 9.53043 2 9L2 3L4 3L4 9L20 9L20 3L22 3L22 9C22 9.53043 21.7893 10.0391 21.4142 10.4142C21.0391 10.7893 20.5304 11 20 11L4 11C3.46957 11 2.96086 10.7893 2.58579 10.4142Z"
          fill="currentColor"
        />
      </svg>
    );
  },
);

PaginatedPlusAfterIcon.displayName = "PaginatedPlusAfterIcon";
