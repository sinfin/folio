const origLog = console.log;
console.log = function () {
    const msgs = []
    msgs.push('[NOTIFY] ' + [].shift.call(arguments));
    msgs.push(...arguments)
    origLog.apply(console, msgs);
};

const origError = console.error;
console.error = function () {
    const msgs = []
    msgs.push('[NOTIFY] ' + [].shift.call(arguments));
    msgs.push(...arguments)
    origError.apply(console, msgs);
};

import {S3Client, GetObjectCommand} from "@aws-sdk/client-s3";
import {
    makeHttpsPostRequest,
    buildBackendURL,
    extractSQSMessage,
    extractS3EventNotificationMessage
} from './utils/utils.js';

const s3Client = new S3Client({});

const BASE_BACKEND_URL = process.env.BASE_BACKEND_URL || "https://dummy.z0ny.net/folio/api/s3"; // Example: 'https://api.example.com/datahandler/'
const API_KEY = process.env.API_KEY || "dummy_header"; // Optional: If your backend requires an API key

// Helper function to stream S3 object content to a Buffer
const streamToBuffer = (stream) =>
    new Promise((resolve, reject) => {
        const chunks = [];
        stream.on("data", (chunk) => chunks.push(chunk));
        stream.on("error", reject);
        stream.on("end", () => resolve(Buffer.concat(chunks)));
    });

export const handler = async (event, context) => {
    try {
        console.log('Received S3 event:', JSON.stringify(event, null, 2));

        if (!BASE_BACKEND_URL) {
            console.error('Error: BASE_BACKEND_URL environment variable is not set.');
            return {
                statusCode: 500,
                body: JSON.stringify('Configuration error: BASE_BACKEND_URL is not set.'),
            };
        }

        // Extract Message from SQS event
        const sqsRecord = extractSQSMessage(event);

        if (sqsRecord.Event === "s3:TestEvent") {
            console.log("Received SQS test event. Skipping.");
            return {
                statusCode: 200,
                body: JSON.stringify("Lambda function finished processing the SQS message batch.")
            };
        }

        // Extract Message from S3 Event Notification
        const s3EventNotificationRecord = extractS3EventNotificationMessage(sqsRecord);

        const s3 = s3EventNotificationRecord.s3;
        const bucketName = s3.bucket.name;
        const objectKey = decodeURIComponent(s3.object.key.replace(/\+/g, ' '));

        console.log(`Processing JSON file: s3://${bucketName}/${objectKey}`);

        if (objectKey.endsWith('.json')) {
            // Get the object from S3
            const getObjectParams = {
                Bucket: bucketName,
                Key: objectKey,
            };
            const getObjectCommand = new GetObjectCommand(getObjectParams);
            const s3Object = await s3Client.send(getObjectCommand);

            // s3Object.Body is a readable stream, convert it to a buffer
            const fileContentBuffer = await streamToBuffer(s3Object.Body);
            console.log(`Successfully retrieved JSON file '${objectKey}' from S3. Size: ${fileContentBuffer.length} bytes.`);

            // Since the file is always JSON, convert the buffer to a UTF-8 string.
            // This string will be the body of our POST request.
            const jsonStringPayload = fileContentBuffer.toString('utf8');
            const backendURL = buildBackendURL(BASE_BACKEND_URL, objectKey, 'processed', true, s3Object.LastModified)
            const response = await makeHttpsPostRequest(backendURL, jsonStringPayload, {
                'X-API-Key': API_KEY
            })

            console.log(`Backend response for ${objectKey}:`, response.statusCode, response.body);

            if (response.statusCode < 200 || response.statusCode >= 300) {
                console.error(`Backend returned an error for ${objectKey}: ${response.statusCode} - ${response.body}`);
                throw new Error(`Backend returned an error for ${objectKey}: ${response.statusCode}`);
            }
        } else {
            const backendURL = buildBackendURL(BASE_BACKEND_URL, objectKey, 'uploaded')
            const response = await makeHttpsPostRequest(backendURL, null, {
                'X-API-Key': API_KEY
            })

            console.log(`Backend response for ${objectKey}:`, response.statusCode, response.body);

            if (response.statusCode < 200 || response.statusCode >= 300) {
                console.error(`Backend returned an error for ${objectKey}: ${response.statusCode} - ${response.body}`);
                throw new Error(`Backend returned an error for ${objectKey}: ${response.statusCode}`);
            }
        }

        return {
            statusCode: 200,
            body: JSON.stringify('Event processed.'),
        };

    } catch (error) {
        console.error('Failed to process event.', error);

        return {
            statusCode: 500,
            body: JSON.stringify({
                message: "Failed to process event.",
                error: error.message,
                errorDetails: error,
            }),
        };
    }
};