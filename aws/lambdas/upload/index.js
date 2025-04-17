const origLog = console.log;
console.log = function () {
    const msgs = []
    msgs.push('[UPLOAD] ' + [].shift.call(arguments));
    msgs.push(...arguments)
    origLog.apply(console, msgs);
};

const origError = console.error;
console.error = function () {
    const msgs = []
    msgs.push('[UPLOAD] ' + [].shift.call(arguments));
    msgs.push(...arguments)
    origError.apply(console, msgs);
};

import {S3Client, HeadObjectCommand, PutObjectCommand} from "@aws-sdk/client-s3";
import path from "path";
import {ContextError} from "./errors/contextError.js";

import {
    extractSQSMessage,
    extractS3EventNotificationMessage,
    getRealMimeType,
    updateS3ObjectContentTypeIfNeeded
} from './utils/utils.js';

// Initialize the S3 Client
const s3Client = new S3Client({
    region: process.env.AWS_REGION || "eu-west-1"
});

// Define the Lambda handler function
export const handler = async (event, context) => {
    try {
        console.log("Received SQS event:", JSON.stringify(event, null, 2));

        // Extract Message from SQS event
        const sqsRecord = extractSQSMessage(event);
        console.log("Parsed SQS event notification:", JSON.stringify(sqsRecord, null, 2));

        if (sqsRecord.Event === "s3:TestEvent") {
            console.log("Received SQS test event. Skipping.");
            return {
                statusCode: 200,
                body: JSON.stringify("Lambda function finished processing the SQS message batch.")
            };
        }

        // Extract Message from S3 Event Notification
        const s3EventNotificationRecord = extractS3EventNotificationMessage(sqsRecord);

        const bucketName = s3EventNotificationRecord.s3.bucket.name;
        const objectKeyEncoded = s3EventNotificationRecord.s3.object.key;
        const objectKey = decodeURIComponent(objectKeyEncoded.replace(/\+/g, " "));

        console.log(`Processing file: s3://${bucketName}/${objectKey}`);

        const headObjectParams = {
            Bucket: bucketName,
            Key: objectKey
        };

        let actualMimeType = null;

        try {
            const detectedTypeResult = await getRealMimeType(s3Client, bucketName, objectKey);

            if (detectedTypeResult) {
                actualMimeType = detectedTypeResult.mime;
                console.log(`Detected actual MIME Type by file-type: ${actualMimeType}`);
            } else {
                console.log('Could not detect file type from buffer using file-type library.');
            }
        } catch (e) {
            console.error('Exception in file-type library.', 2);
        }


        try {
            // Retrieve object metadata from S3
            const metadataResponse = await s3Client.send(new HeadObjectCommand(headObjectParams));

            const mimeTypeUpdated = await updateS3ObjectContentTypeIfNeeded(
                s3Client,
                bucketName,
                objectKey,
                metadataResponse,
                metadataResponse.ContentType
            );

            if (mimeTypeUpdated) {
                console.log(`Content-Type for s3://${bucketName}/${objectKey} updated to '${actualMimeType}'.`);
            }

            // Construct the metadata object to be saved
            const fileMetadata = {
                fileName: path.basename(objectKey),
                originalPath: objectKey,
                bucket: bucketName,
                sizeBytes: metadataResponse.ContentLength,
                contentType: actualMimeType,
                uploadedContentType: metadataResponse.ContentType,
                lastModified: metadataResponse.LastModified?.toISOString(),
                eTag: metadataResponse.ETag?.replace(/"/g, ""),
                userMetadata: metadataResponse.Metadata,
                processingTimestamp: new Date().toISOString(), // Timestamp of when metadata was processed
            };

            console.log(`Extracted metadata for s3://${bucketName}/${objectKey}:`, JSON.stringify(fileMetadata, null, 2));

            // Get file path
            const originalFileDir = path.dirname(objectKey);

            // Construct full S3 path for metadata file
            const metadataS3Key = `${originalFileDir}/metadata.json`;

            // Convert the fileMetadata object to a pretty-printed JSON string
            const metadataContent = JSON.stringify(fileMetadata, null, 2);

            // Prepare parameters for the PutObjectCommand
            const putObjectParams = {
                Bucket: bucketName,
                Key: metadataS3Key,
                Body: metadataContent,
                ContentType: "application/json"
            };

            // Upload the metadata.json file to S3
            await s3Client.send(new PutObjectCommand(putObjectParams));

            console.log(`Successfully saved metadata to s3://${bucketName}/${metadataS3Key}`);
        } catch (e) {
            let message = "S3 processing failed";
            if (e.name === "NoSuchKey" || e.name === "NotFound") {
                message = "S3 object not found";
            }

            throw new ContextError(message, {
                objectKey: objectKey,
                Bucket: bucketName,
                cause: e,
            });
        }

        return {
            statusCode: 200,
            body: JSON.stringify("Event processed."),
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