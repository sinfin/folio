import * as React from "react";

export const LoaderIcon = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="24"
        height="24"
        className={className}
        viewBox="0 0 24 24"
        fill="currentColor"
        xmlns="http://www.w3.org/2000/svg"
        {...props}
      >
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M12 2C12.5523 2 13 2.44772 13 3V6C13 6.55228 12.5523 7 12 7C11.4477 7 11 6.55228 11 6V3C11 2.44772 11.4477 2 12 2Z"
          fill="currentColor"
          opacity="0.2"
        />
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M16.9497 4.22183C17.3402 4.61236 17.3402 5.24552 16.9497 5.63604L14.8284 7.75736C14.4379 8.14789 13.8047 8.14789 13.4142 7.75736C13.0237 7.36684 13.0237 6.73367 13.4142 6.34315L15.5355 4.22183C15.926 3.8313 16.5592 3.8313 16.9497 4.22183Z"
          fill="currentColor"
          opacity="0.3"
        />
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M22 12C22 12.5523 21.5523 13 21 13H18C17.4477 13 17 12.5523 17 12C17 11.4477 17.4477 11 18 11H21C21.5523 11 22 11.4477 22 12Z"
          fill="currentColor"
          opacity="0.4"
        />
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M19.7782 16.9497C20.1687 16.5592 20.1687 15.926 19.7782 15.5355L17.6569 13.4142C17.2663 13.0237 16.6332 13.0237 16.2426 13.4142C15.8521 13.8047 15.8521 14.4379 16.2426 14.8284L18.364 16.9497C18.7545 17.3402 19.3876 17.3402 19.7782 16.9497Z"
          fill="currentColor"
          opacity="0.5"
        />
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M12 17C12.5523 17 13 17.4477 13 18V21C13 21.5523 12.5523 22 12 22C11.4477 22 11 21.5523 11 21V18C11 17.4477 11.4477 17 12 17Z"
          fill="currentColor"
          opacity="0.6"
        />
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M7.05025 19.7782C7.44078 20.1687 7.44078 20.8019 7.05025 21.1924C6.65973 21.5829 6.02656 21.5829 5.63604 21.1924L3.51472 19.0711C3.12419 18.6805 3.12419 18.0474 3.51472 17.6569C3.90524 17.2663 4.53841 17.2663 4.92893 17.6569L7.05025 19.7782Z"
          fill="currentColor"
          opacity="0.7"
        />
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M7 12C7 12.5523 6.55228 13 6 13H3C2.44772 13 2 12.5523 2 12C2 11.4477 2.44772 11 3 11H6C6.55228 11 7 11.4477 7 12Z"
          fill="currentColor"
          opacity="0.8"
        />
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M4.22183 7.05025C4.61236 7.44078 5.24552 7.44078 5.63604 7.05025L7.75736 4.92893C8.14789 4.53841 8.14789 3.90524 7.75736 3.51472C7.36684 3.12419 6.73367 3.12419 6.34315 3.51472L4.22183 5.63604C3.8313 6.02656 3.8313 6.65973 4.22183 7.05025Z"
          fill="currentColor"
          opacity="0.9"
        />
      </svg>
    );
  },
);

LoaderIcon.displayName = "LoaderIcon";
