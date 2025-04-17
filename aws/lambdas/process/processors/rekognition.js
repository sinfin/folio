import {RekognitionClient, DetectLabelsCommand} from "@aws-sdk/client-rekognition";
import {S3Client, PutObjectCommand} from "@aws-sdk/client-s3";
import path from "path";

const AWS_REGION = process.env.AWS_REGION || "eu-west-1";
const rekognitionClient = new RekognitionClient({region: AWS_REGION});
const s3Client = new S3Client({region: AWS_REGION});

const ALLOWED_MIME_TYPES = [
    'image/jpeg',
    'image/png',
    'video/mp4',
    'video/mov'
]

export async function processEvent(bucketName, objectKey, mimeType) {
    if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
        throw new Error(`Invalid mime type ${mimeType} for Rekognition`);
    }

    const params = {
        Image: {
            S3Object: {
                Bucket: bucketName, Name: objectKey,
            },
        }, MaxLabels: 10, // Maximum number of labels to return
        MinConfidence: 75, // Minimum confidence level for labels to return
    };

    const command = new DetectLabelsCommand(params);
    const rekognitionData = await rekognitionClient.send(command);

    console.log("Rekognition API response:", rekognitionData);

    // Get file path
    const originalFileDir = path.dirname(objectKey);

// Construct full S3 path for metadata file
    const metadataS3Key = `${originalFileDir}/rekognition.metadata.json`;

    // Convert the fileMetadata object to a pretty-printed JSON string
    const metadataContent = JSON.stringify(rekognitionData, null, 2);

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
}