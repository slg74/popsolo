require "aws-sdk-dynamodb"

opts = {
  region:            ENV.fetch("AWS_REGION", "us-east-1"),
  access_key_id:     ENV.fetch("AWS_ACCESS_KEY_ID",     "fake"),
  secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY", "fake")
}

# When DYNAMODB_ENDPOINT is set (e.g. http://localhost:8000), use DynamoDB Local.
# Credentials can be anything — local ignores them.
opts[:endpoint] = ENV["DYNAMODB_ENDPOINT"] if ENV["DYNAMODB_ENDPOINT"].present?

AWS_DYNAMODB = Aws::DynamoDB::Client.new(**opts)
