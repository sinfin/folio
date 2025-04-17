export class ContextError extends Error {
    constructor(message, data = {}) {
        super(message);
        this.name = this.constructor.name;

        this.context = data

        if (Error.captureStackTrace) {
            Error.captureStackTrace(this, ContextError);
        }
    }
}