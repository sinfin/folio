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