require "aws-sdk-dynamodb"

AWS_DYNAMODB = Aws::DynamoDB::Client.new(
  region: ENV.fetch("AWS_REGION", "us-east-1"),
  access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
)
