#!/usr/bin/env bash

set -o pipefail

# GitHub app needs to have a client ID and a private key.
CLIENT_ID=$TEST_GITHUB_APP_CLIENT_ID
PRIVATE_KEY_FILE=$TEST_GITHUB_APP_PRIVATE_KEY_FILE
OWNER=$TEST_OWNER
REPO=$TEST_REPO

echo "Client ID: $CLIENT_ID"

# Validate required environment variables
if [[ -z "$CLIENT_ID" || -z "$PRIVATE_KEY_FILE" || -z "$OWNER" || -z "$REPO" ]]; then
    echo "Error: Missing required environment variables"
    exit 1
fi

# Check if private key file exists
if [[ ! -f "$PRIVATE_KEY_FILE" ]]; then
    echo "Error: Private key file not found: $PRIVATE_KEY_FILE"
    exit 1
fi

# Generate JWT for GitHub App authentication
# See https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app#example-using-bash-to-generate-a-jwt

client_id=$CLIENT_ID
pem=$( cat "$PRIVATE_KEY_FILE" )

now=$(date +%s)
# shellcheck disable=SC2004
iat=$((${now} - 60)) # Issues 60 seconds in the past
# shellcheck disable=SC2004
exp=$((${now} + 600)) # Expires 10 minutes in the future

b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

header_json='{
    "typ":"JWT",
    "alg":"RS256"
}'
# Header encode
header=$( echo -n "${header_json}" | b64enc )

payload_json="{
    \"iat\":${iat},
    \"exp\":${exp},
    \"iss\":\"${client_id}\"
}"
# Payload encode
payload=$( echo -n "${payload_json}" | b64enc )

# Signature
header_payload="${header}"."${payload}"
signature=$(
    openssl dgst -sha256 -sign <(echo -n "${pem}") \
    <(echo -n "${header_payload}") | b64enc
)

# Create JWT
JWT="${header_payload}"."${signature}"
printf '%s\n' "JWT: $JWT"

# Get installation info
echo "Getting installation info..."
INSTALLATION_INFO=$(gh api "/repos/${OWNER}/${REPO}/installation" --header "Authorization: Bearer ${JWT}")
APP_SLUG=$(echo "$INSTALLATION_INFO" | jq -r '.app_slug')
INSTALLATION_ID=$(echo "$INSTALLATION_INFO" | jq -r '.id')

echo "App slug: $APP_SLUG"
echo "Installation ID: $INSTALLATION_ID"

# Get user ID for the bot
USER_ID=$(gh api "/users/${APP_SLUG}[bot]" --jq .id)
echo "Bot user ID: $USER_ID"

# Get installation access token with restricted permissions
echo "Getting installation access token with restricted permissions..."
ACCESS_TOKEN_RESPONSE=$(gh api "/app/installations/${INSTALLATION_ID}/access_tokens" \
    --method POST \
    --header "Authorization: Bearer ${JWT}" \
    --field permissions[metadata]=read \
    --field permissions[contents]=write \
    --field permissions[pull_requests]=write \
)
ACCESS_TOKEN=$(echo "$ACCESS_TOKEN_RESPONSE" | jq -r '.token')

echo "Access token obtained"

export GH_TOKEN=$ACCESS_TOKEN

#echo "*** repo ***"
#gh api /repos/"$OWNER"/"$REPO"

#echo "*** branches ***"
#gh api /repos/"$OWNER"/"$REPO"/branches

#echo "*** PRs ***"
#gh api /repos/OWNER/REPO/pulls

#gh api /installation/repositories

# Create a basic PR
gh api /repos/"$OWNER"/"$REPO"/pulls \
  --method POST \
  --field title="Testing github app" \
  --field body="This is a test PR to verify GitHub App permissions" \
  --field head="add-6.189.121953-to-release-tracker" \
  --field base="main" \
  --field draft=true
