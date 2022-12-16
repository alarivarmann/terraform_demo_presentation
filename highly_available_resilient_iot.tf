# This code creates an IoT thing for the sensor, an IoT policy that allows the sensor to publish messages 
# to the IoT topic, and attaches the policy to the sensor. 
# This allows the sensor to send data directly to the IoT topic, 
# which then sends the data to the SNS topic and SQS queue for further processing.

# To reduce latency, you can use the AWS IoT Core MQTT protocol to send messages 
# from the sensor to the IoT topic. MQTT is a lightweight publish-subscribe messaging protocol.

# Create an IoT thing for the sensor
resource "aws_iot_thing" "my_sensor" {
  name = "my-sensor"
}

# Create an IoT policy for the sensor
resource "aws_iot_policy" "my_sensor_policy" {
  name = "my-sensor-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Publish"
      ],
      "Resource": [
        "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/${aws_iot_topic_rule.my_rule.topic}"
      ]
    }
  ]
}
POLICY
}

# Attach the policy to the sensor
resource "aws_iot_policy_attachment" "my_sensor_policy_attachment" {
  policy_name = aws_iot_policy.my_sensor_policy.name
  target = aws_iot_thing.my_sensor.arn
}

# Create an IoT topic
resource "aws_iot_topic_rule" "my_rule" {
  name = "my-rule"
  topic = "my-topic"

  # Send messages to an SNS topic
  action {
    sns {
      target_arn = aws_sns_topic.my_topic.arn
    }
  }
}

# Create an SNS topic
resource "aws_sns_topic" "my_topic" {
  name = "my-topic"
}

# Create a SQS queue for the SNS topic
resource "aws_sqs_queue" "my_queue" {
  name = "my-queue"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.my_dead_letter_queue.arn
    maxReceiveCount = 3
  })
}

# Create a dead letter queue for the main queue
resource "aws_sqs_queue" "my_dead_letter_queue" {
  name = "my-dead-letter-queue"
}

# Subscribe the SQS queue to the SNS topic
resource "aws_sns_topic_subscription" "my_queue_subscription" {
  topic_arn = aws_sns_topic.my_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.my_queue.arn
}