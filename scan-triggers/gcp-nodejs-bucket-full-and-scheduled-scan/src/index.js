// Copyright (C) 2024 Trend Micro Inc. All rights reserved.

const { PubSub } = require('@google-cloud/pubsub')
const { Storage } = require('@google-cloud/storage')

const fs = require('fs')

const scannerQueueTopic = process.env.SCANNER_PUBSUB_TOPIC
const scannerProjectID = process.env.SCANNER_PROJECT_ID
const scanResultTopic = process.env.SCAN_RESULT_TOPIC
const deploymentName = process.env.DEPLOYMENT_NAME
const reportObjectKey = process.env.REPORT_OBJECT_KEY === 'True'

const storage = new Storage()
const pubSubClient = new PubSub({ projectId: scannerProjectID })

let version
try {
  const rawData = fs.readFileSync('package.json')
  version = JSON.parse(rawData).version
} catch (error) {
  console.log('failed to get version.', error)
}

/**
 * Triggered from a change to a Cloud Storage bucket.
 *
 * @param {!Object} event Event payload.
 */
exports.handler = async (event) => {
  const fileName = event.name
  const bucket = event.bucket

  console.log(`Function version: ${version}`)

  if (!fileName.startsWith(objectFilterPrefix)) {
    console.log('Skip scanning object')
    return
  }

  const url = await generateV4ReadSignedUrl(bucket, fileName).catch(console.error)
  const { crc32c, etag } = await getFileAttributes(bucket, fileName).catch(console.error)

  const scanMessage = {
    signed_url: url,
    scan_result_topic: scanResultTopic,
    deployment_name: deploymentName,
    report_object_key: reportObjectKey,
    file_attributes: {
      etag,
      checksums: {
        crc32c
      }
    }
  }
  await publishMessage(JSON.stringify(scanMessage), scannerQueueTopic)
}

async function generateV4ReadSignedUrl(bucketName, fileName) {
  try {
    // These options will allow temporary read access to the file
    const options = {
      version: 'v4',
      action: 'read',
      expires: Date.now() + 60 * 60 * 1000 // 1 hour
    }

    // Get a v4 signed URL for reading the file
    const [url] = await storage
      .bucket(bucketName)
      .file(fileName)
      .getSignedUrl(options)

    return url
  } catch (error) {
    console.error('Failed to sign an url:', error)
    throw error
  }
}

async function getFileAttributes(bucketName, fileName) {
  try {
    const [metadata] = await storage.bucket(bucketName).file(fileName).getMetadata()
    console.log(`File metadata: ${JSON.stringify(metadata)}`)
    return {
      crc32c: metadata.crc32c,
      etag: metadata.etag
    }
  } catch (error) {
    console.error('Failed to get file metadata:', error)
    throw error
  }
}

async function publishMessage(message, topic) {
  try {
    const messageId = await pubSubClient.topic(topic).publishMessage({ data: Buffer.from(message) })
    console.log(`Message ${messageId} published.`)
  } catch (error) {
    console.error('Received error while publishing scan message:', error)
    throw error
  }
}
