import {GetObjectCommand} from "@aws-sdk/client-s3";
import {fileTypeFromBuffer} from "file-type";
import {ContextError} from "../errors/contextError.js";

export function extractSQSMessage(event) {
    if (!event.Records) {
        throw new ContextError("SQS event does not contain 'Records'", {
            event: JSON.stringify(event, null, 2)
        });
    }

    // Batch is set 1 so there will be always only one message
    const sqsRecord = event.Records.at(0);

    if (sqsRecord === undefined) {
        throw new ContextError("SQS event does not contain any records", {
            event: JSON.stringify(event, null, 2)
        });
    }

    if (!sqsRecord.body) {
        throw new ContextError("SQS event record body is missing", {
            event: JSON.stringify(sqsRecord, null, 2)
        });
    }

    return JSON.parse(sqsRecord.body);
}

export function extractS3EventNotificationMessage(event) {
    if (!event.Records) {
        throw new ContextError("S3 event notification does not contain 'Records'", {
            event: JSON.stringify(event, null, 2)
        });
    }

    // Batch is set 1 so there will be always only one message
    const s3EventNotificationRecord = event.Records.at(0);

    if (s3EventNotificationRecord === undefined) {
        throw new ContextError("S3 event notification does not contain any records", {
            event: JSON.stringify(event, null, 2)
        });
    }

    if (!s3EventNotificationRecord.s3 || !s3EventNotificationRecord.s3.bucket || !s3EventNotificationRecord.s3.object) {
        throw new ContextError("S3 bucket or object information is missing in S3 event record", {
            event: JSON.stringify(event, null, 2)
        });
    }

    return s3EventNotificationRecord;
}

export async function getRealMimeType(s3Client, bucketName, objectKey) {
    try {
        const getObjectParams = {
            Bucket: bucketName,
            Key: objectKey,
            Range: "bytes=0-4100",
        };
        const getObjectResponse = await s3Client.send(new GetObjectCommand(getObjectParams));

        const chunks = [];
        for await (const chunk of getObjectResponse.Body) {
            chunks.push(chunk);
        }
        const buffer = Buffer.concat(chunks);

        return await fileTypeFromBuffer(buffer);
    } catch (e) {
        throw new ContextError("Get real Mime Type of the file failed", {
            objectKey: objectKey,
            Bucket: bucketName,
            cause: e,
        });
    }
}

/**
 * Updates the Content-Type of an S3 object if the detected actualMimeType differs
 * from the one stored in headObjectResponse.
 * This function copies the object over itself with the new Content-Type,
 * attempting to preserve other existing metadata.
 *
 * @param {S3Client} s3Client - The initialized AWS SDK v3 S3 client.
 * @param {string} bucketName - The name of the S3 bucket.
 * @param {string} objectKey - The key of the S3 object.
 * @param {object} headObjectResponse - The response from a HeadObjectCommand for the object.
 * This contains current metadata like ContentType, Metadata, ETag, etc.
 * @param {string | null} actualMimeType - The new, detected MIME type. If null or undefined, no update will be attempted.
 * @returns {Promise<boolean>} True if an update was successfully attempted, false otherwise (e.g., types matched or actualMimeType was null).
 * @throws {Error} Throws an error if the CopyObject operation fails.
 */
export async function updateS3ObjectContentTypeIfNeeded(s3Client, bucketName, objectKey, headObjectResponse, actualMimeType) {
    // Extract stored Content-Type from headObjectResponse
    const storedContentType = headObjectResponse.ContentType;

    // Normalize types for comparison (lowercase, strip charset parameters)
    const normalizedStored = storedContentType ? storedContentType.toLowerCase().split(';')[0].trim() : null;
    const normalizedActual = actualMimeType ? actualMimeType.toLowerCase() : null;

    if (!actualMimeType || normalizedStored === normalizedActual) {
        return false;
    }

    // Prepare parameters for CopyObjectCommand
    const copyParams = {
        Bucket: bucketName,
        Key: objectKey,
        // CopySource must be in the format 'bucket/key'. The key part should be URL-encoded.
        CopySource: `${bucketName}/${encodeURIComponent(objectKey)}`,
        MetadataDirective: 'REPLACE', // Indicates that metadata is being replaced

        // Set the new ContentType
        ContentType: actualMimeType,

        // Preserve user-defined metadata (if it exists)
        Metadata: headObjectResponse.Metadata,

        // Preserve storage class (if it exists, otherwise S3 default or original)
        StorageClass: headObjectResponse.StorageClass, // Or use 'STANDARD' as a default if preferred

        // Preserve object tags by copying them from the source
        TaggingDirective: 'COPY', // Lambda role needs s3:GetObjectTagging permission on the source object

        // Use ETag for conditional copy (atomicity)
        CopySourceIfMatch: headObjectResponse.ETag,
    };

    // List of other system metadata headers to preserve if they exist.
    // These are common headers returned by HeadObject and settable by CopyObject.
    const systemMetadataKeysToPreserve = [
        'CacheControl',
        'ContentDisposition',
        'ContentEncoding',
        'ContentLanguage',
        'Expires',
        'WebsiteRedirectLocation'
        // ContentType and StorageClass are handled explicitly above.
        // User metadata (Metadata) is also handled explicitly.
    ];

    systemMetadataKeysToPreserve.forEach(key => {
        if (headObjectResponse[key] !== undefined) {
            copyParams[key] = headObjectResponse[key];
        }
    });

    // Clean up any parameters that might have an explicit 'undefined' value,
    // as the SDK might not handle them gracefully. Omitting the key is preferred.
    for (const key in copyParams) {
        if (copyParams[key] === undefined) {
            delete copyParams[key];
        }
    }

    try {
        await s3Client.send(new CopyObjectCommand(copyParams));
        return true; // Update attempted and (presumably) succeeded
    } catch (e) {
        throw new ContextError("Failed to update Content-Type in S3", {
            objectKey: objectKey,
            Bucket: bucketName,
            ActualMimeType: actualMimeType,
            cause: e,
        });
    }
}