const origLog = console.log;
console.log = function () {
    const msgs = []
    msgs.push('[PROCESS] ' + [].shift.call(arguments));
    msgs.push(...arguments)
    origLog.apply(console, msgs);
};

const origError = console.error;
console.error = function () {
    const msgs = []
    msgs.push('[PROCESS] ' + [].shift.call(arguments));
    msgs.push(...arguments)
    origError.apply(console, msgs);
};

import {extractSQSMessage} from './utils/utils.js';
import {processEvent} from './processors/rekognition.js';

const S3_BUCKET_NAME = process.env.S3_BUCKET_NAME || "hosting-prodsinfin-folio-demo";

export const handler = async (event) => {
    try {
        console.log("Received event:", JSON.stringify(event, null, 2));

        // Extract Message from SQS event
        const sqsRecord = extractSQSMessage(event);

        console.log("Event body:", sqsRecord);

        const options = sqsRecord.options;
        const objectKey = sqsRecord.s3_path;
        const mimeType = sqsRecord.mime_type;

        if (!S3_BUCKET_NAME || !objectKey) {
            console.error("S3 bucket name or object key not found in the event.");
            return {
                statusCode: 400,
                body: JSON.stringify({message: "S3 bucket name or object key missing in the event."})
            };
        }

        console.log(`Processing: s3://${S3_BUCKET_NAME}/${objectKey}`, mimeType, options);

        if (options.rekognition) {
            await processEvent(S3_BUCKET_NAME, objectKey, mimeType);
        }

        return {
            statusCode: 200,
            body: JSON.stringify('Event processed.')
        };
    } catch (error) {
        console.error('Failed to process event.', error);

        return {
            statusCode: 500,
            body: JSON.stringify({
                message: "Failed to process event.",
                error: error.message,
                errorDetails: error
            }),
        };
    }
};