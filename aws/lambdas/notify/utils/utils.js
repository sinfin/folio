// We need the 'https' module for making requests and 'URL' for parsing the URL string.
import https from 'node:https';
import {URL} from 'node:url'; // For parsing the URL

/**
 * Makes an HTTPS POST request.
 * @param {string} urlString - The full URL to which the POST request will be made.
 * @param {string | null} [payload=null] - The string payload to send. If null, an empty body request is made.
 * If it's an empty string "", a POST with an empty body and Content-Length: 0 is made.
 * If it's JSON, it should be stringified before passing.
 * @param {Record<string, string>} [customHeaders={}] - Optional custom headers to include in the request.
 * @returns {Promise<{statusCode: number | undefined, headers: object, body: string}>} - A promise that resolves with the response.
 */
export async function makeHttpsPostRequest(urlString, payload = null, customHeaders = {}) {
    return new Promise((resolve, reject) => {
        const url = new URL(urlString); // Parse the URL string to extract hostname, path, etc.

        // Prepare headers
        const headers = {...customHeaders}; // Start with any custom headers provided

        if (payload != null) { // If a payload is provided (this includes an empty string)
            // Set Content-Type if not already set in customHeaders, defaulting to application/json
            // This is a common default, adjust if your payload is not JSON.
            headers['Content-Type'] = headers['Content-Type'] || 'application/json';
            headers['Content-Length'] = Buffer.byteLength(payload);
        } else { // No payload (payload is null or undefined), meaning POST with empty body
            headers['Content-Length'] = '0';
            // If a Content-Type (like application/json) was in customHeaders, it will remain.
            // For truly empty body POSTs, some APIs might not expect a Content-Type,
            // or they might expect a specific one. Content-Length: 0 is the key part.
        }

        const options = {
            hostname: url.hostname,
            path: url.pathname + url.search, // Ensure query parameters from URL are included
            method: 'POST',
            headers: headers,
        };

        // If the URL specifies a port, add it to the options
        if (url.port) {
            options.port = url.port;
        }

        const req = https.request(options, (res) => {
            let responseBody = '';
            res.on('data', (chunk) => {
                responseBody += chunk;
            });
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    body: responseBody,
                });
            });
        });

        req.on('error', (error) => {
            // Using urlString in the error message for better context
            console.error(`Error making POST request to ${urlString}:`, error);
            reject(error);
        });

        // Write the payload to the request body and end the request.
        // If payload is null or undefined, req.end() is called without data.
        // If payload is a string (even an empty one), it's passed to req.end().
        if (payload != null) {
            req.write(payload);
        }
        req.end();
        // A more concise way to do the above write and end for Node.js:
        // req.end(payload); // If payload is null/undefined, this is fine. If string, data is sent.
        // However, the explicit req.write + req.end is also perfectly clear.
        // For this example, I'll stick to the slightly more verbose but explicit version above.
    });
}

/**
 * Constructs a backend URL based on a base URL, an object key, and an action.
 * This function assumes a specific structure for the objectKey, typically like:
 * 'optional/path/segments/fileType/fileUUID/fileName.ext'
 *
 * @param {string} baseUrl - The base URL of the backend API (e.g., "https://api.example.com/data").
 * This should not have dynamic segments, just the static base path.
 * @param {string} objectKey - The key of the object, typically a file path (e.g., from S3).
 * Example: "uploads/images/123e4567-e89b-12d3-a456-426614174000/photo.jpg"
 * @param {string} action - The action to be performed on the resource, used as a path segment in the URL.
 * Example: "process", "view", "analyze"
 * @param {boolean} withFileName - If file name should be at end of path
 * @returns {string} The fully constructed backend URL.
 * Example: "https://api.example.com/data/process/images/123e4567-e89b-12d3-a456-426614174000/photo.jpg"
 */
export function buildBackendURL(baseUrl, objectKey, action, withFileName = false, lastModified = nil) {
    // --- Prerequisite Check (Basic) ---
    // Ensure baseUrl is provided, otherwise the function cannot operate correctly.
    if (!baseUrl || typeof baseUrl !== 'string' || baseUrl.trim() === '') {
        console.error("Error: baseUrl parameter is required and must be a non-empty string.");
        // Returning a placeholder or throwing an error might be appropriate
        // depending on desired error handling strategy.
        return "invalid_base_url_provided";
    }

    // --- 1. Parse the objectKey ---
    // Split the objectKey string by '/' to get its constituent parts.
    // The filter(part => part.length > 0) removes any empty strings that might result
    // from leading, trailing, or multiple consecutive slashes in the objectKey (e.g., "folder//file.txt").
    const pathParts = objectKey.split('/').filter(part => part.length > 0);

    // Extract the fileName:
    // .pop() removes and returns the last element from the pathParts array.
    // This is assumed to be the actual file name with its extension.
    const fileName = pathParts.pop(); // e.g., "photo.jpg"

    // Extract the fileUUID (Universally Unique Identifier):
    // If there are still parts left in pathParts after extracting fileName,
    // the new last part is assumed to be the fileUUID.
    // If pathParts is empty at this point (meaning objectKey was just "fileName.ext"),
    // fileUUID will be set to null.
    const fileUUID = pathParts.length > 0 ? pathParts.pop() : null; // e.g., "123e4567-e89b-12d3-a456-426614174000" or null

    // Extract the fileType:
    // Similarly, if parts remain after extracting fileUUID,
    // the new last part is assumed to be the fileType (e.g., "images", "documents").
    // If pathParts is empty here (meaning objectKey was "fileUUID/fileName.ext" or "fileName.ext"),
    // fileType will be set to null.
    const fileType = pathParts.length > 0 ? pathParts.pop() : null; // e.g., "images" or null

    // --- 2. Prepare the Base URL from Parameter ---
    // Use the provided `baseUrl` parameter.
    // Ensure it does not end with a trailing slash to prevent potential double slashes
    // (e.g., "https://api.example.com//action") when appending further path segments.
    const normalizedBaseUrl = baseUrl.replace(/\/$/, '');

    // --- 4. Construct the Full Backend URL ---
    // Assemble the final URL using template literals for readability.
    // The structure is: {normalizedBaseUrl}/{action}/{fileType}/{fileUUID}/{encodedFileName}
    //
    // IMPORTANT NOTE on null values:
    // If fileType or fileUUID were determined to be `null` in step 1,
    // they will be interpolated as the string "null" in the URL path.
    // For example: ".../action/null/123-abc/file.jpg" or ".../action/null/null/file.jpg".
    // Ensure your backend API is prepared to handle "null" as a path segment
    // or adjust this logic if null segments should be omitted instead.
    let backendUrl = `${normalizedBaseUrl}/${action}/${fileType}/${fileUUID}`;

    // Add File name at end if required
    if (withFileName) {
        // --- 3. Encode the File Name ---
        // The file name needs to be URL-encoded to handle special characters
        // (like spaces, '&', '?', etc.) that have specific meanings in URLs or are invalid.
        // encodeURIComponent() converts these characters into a safe format (e.g., space becomes %20).
        const encodedFileName = encodeURIComponent(fileName);

        backendUrl += `/${encodedFileName}`
    }

    // Append parameter when file was modified last. Required for *.metadata.json files to verify new version
    if (lastModified) {
        backendUrl += `?fileLastModified=${encodeURIComponent(lastModified)}`
    }

    // --- 5. Log the Generated URL (Optional) ---
    // This console log is useful for debugging purposes, allowing you to see
    // the generated URL in your Lambda logs or server console.
    console.log(`Target backend URL: ${backendUrl}`);

    // --- 6. Return the Constructed URL ---
    return backendUrl;
}

export function extractSQSMessage(event) {
    if (!event.Records) {
        console.error("ERROR: SQS event does not contain 'Records'. Notification:", JSON.stringify(event, null, 2));
        throw new Error("SQS event does not contain 'Records'");
    }

    // Batch is set 1 so there will be always only one message
    const sqsRecord = event.Records.at(0);

    if (sqsRecord === undefined) {
        console.error("ERROR: SQS event does not contain any records. Notification:", JSON.stringify(event, null, 2));
        throw new Error('SQS event does not contain any records');
    }

    console.log("Processing SQS event record with messageId:", sqsRecord.messageId);

    if (!sqsRecord.body) {
        console.log("ERROR: SQS event record body is missing. Record:", JSON.stringify(sqsRecord, null, 2))
        throw new Error("SQS event record body is missing");
    }

    const sqsEventNotification = JSON.parse(sqsRecord.body);
    console.log("Parsed SQS event notification:", JSON.stringify(sqsEventNotification, null, 2));

    return sqsEventNotification;
}

export function extractS3EventNotificationMessage(event) {
    if (!event.Records) {
        console.error("ERROR: S3 event notification does not contain 'Records'. Notification:", JSON.stringify(event, null, 2));
        throw new Error("S3 event notification does not contain 'Records'");
    }

    // Batch is set 1 so there will be always only one message
    const s3EventNotificationRecord = event.Records.at(0);

    if (s3EventNotificationRecord === undefined) {
        console.error("ERROR: S3 event notification does not contain any records. Notification:", JSON.stringify(event, null, 2));
        throw new Error('S3 event notification does not contain any records');
    }

    if (!s3EventNotificationRecord.s3 || !s3EventNotificationRecord.s3.bucket || !s3EventNotificationRecord.s3.object) {
        console.error("ERROR: S3 bucket or object information is missing in S3 event record. Record:", JSON.stringify(s3EventNotificationRecord, null, 2));
        throw new Error('S3 bucket or object information is missing in S3 event record');
    }

    return s3EventNotificationRecord;
}