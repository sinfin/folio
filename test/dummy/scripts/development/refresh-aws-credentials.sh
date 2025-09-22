#!/bin/bash

PROFILE_NAME="sinfin-s3"
ENV_FILE=".env"

echo "🔄 Refreshing AWS credentials..."

# Login to SSO if needed
aws sso login --profile "$PROFILE_NAME"

# Get credentials and update .env
echo "📝 Updating .env file..."

# Backup .env
cp "$ENV_FILE" "${ENV_FILE}.backup"

# Get new credentials
CREDS=$(aws configure export-credentials --profile "$PROFILE_NAME" --format env)
eval "$CREDS"

# Update .env file
# Function to update or add environment variable
update_or_add_env_var() {
    local var_name="$1"
    local var_value="$2"
    
    if grep -q "^${var_name}=" "$ENV_FILE"; then
        # Update existing variable - handle macOS/Linux sed differences
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS (BSD sed)
            sed -i "" "s|^${var_name}=.*|${var_name}=\"${var_value}\"|" "$ENV_FILE"
        else
            # Linux (GNU sed)
            sed -i "s|^${var_name}=.*|${var_name}=\"${var_value}\"|" "$ENV_FILE"
        fi
    else
        # Add new variable
        echo "${var_name}=\"${var_value}\"" >> "$ENV_FILE"
    fi
}

# Set static S3 configuration
update_or_add_env_var "S3_SCHEME" "https"
update_or_add_env_var "S3_REGION" "eu-west-1"
update_or_add_env_var "S3_BUCKET_NAME" "sinfin-staging"

update_or_add_env_var "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID"
update_or_add_env_var "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY"
update_or_add_env_var "AWS_SESSION_TOKEN" "$AWS_SESSION_TOKEN"

echo "✅ Done! Your .env file has been updated with fresh AWS credentials."
