import * as React from "react";
import { AlertCircleIcon } from "@/components/tiptap-icons";
import translate from "@/lib/i18n";

import "./invalid-node-indicator.scss";

const CLASS_NAME = "f-tiptap-invalid-node-indicator";

const TRANSLATIONS = {
  cs: {
    title: "Nevalidní obsah",
    errorMessageHint: "Chyba",
  },
  en: {
    title: "Invalid content",
    errorMessageHint: "Error",
  },
};

const DEFAULT_INVALID_NODE_HASH = {
  type: "Unknown type",
};

interface InvalidNodeIndicatorProps {
  invalidNodeHash?: Record<string, unknown>;
  message?: string;
  errorMessage?: string;
}

export const InvalidNodeIndicator = ({
  invalidNodeHash,
  message,
  errorMessage,
}: InvalidNodeIndicatorProps) => {
  return (
    <div className={CLASS_NAME}>
      <h4 className={`${CLASS_NAME}__title`}>
        <AlertCircleIcon />
        {translate(TRANSLATIONS, "title")}
      </h4>

      {message && <p className={`${CLASS_NAME}__message`}>{message}</p>}

      {errorMessage && (
        <p className={`${CLASS_NAME}__message`}>
          <strong>{translate(TRANSLATIONS, "errorMessageHint")}:</strong>{" "}
          {errorMessage}
        </p>
      )}

      <pre className={`${CLASS_NAME}__pre`}>
        <code>
          {JSON.stringify(
            invalidNodeHash || DEFAULT_INVALID_NODE_HASH,
            null,
            2,
          )}
        </code>
      </pre>
    </div>
  );
};

InvalidNodeIndicator.displayName = "InvalidNodeIndicator";

export default InvalidNodeIndicator;
