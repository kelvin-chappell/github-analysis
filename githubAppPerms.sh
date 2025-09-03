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
pem=$( cat $PRIVATE_KEY_FILE )

now=$(date +%s)
iat=$((${now} - 60)) # Issues 60 seconds in the past
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
    --input - <<< '{"permissions":{"metadata":"read","contents":"write"}}')
ACCESS_TOKEN=$(echo "$ACCESS_TOKEN_RESPONSE" | jq -r '.token')

echo "Access token obtained"

# Prepare workspace
cd ~/Desktop/tmp || exit 1
rm -rf "$REPO" 2>/dev/null
echo "Cloning repository..."

# Clone repository using GitHub app credentials
git clone "https://x-access-token:${ACCESS_TOKEN}@github.com/${OWNER}/${REPO}.git"
cd "$REPO" || exit 1

echo "Repository cloned successfully"

# Configure Git to use the access token for HTTPS authentication
git config --local --unset-all credential.helper 2>/dev/null || true
git config --local credential.helper store
echo "https://x-access-token:${ACCESS_TOKEN}@github.com" > .git/git-credentials
git config --local credential.helper "store --file=.git/git-credentials"

# Configure git user for the GitHub App
git config --local user.name "${APP_SLUG}[bot]"
git config --local user.email "${USER_ID}+${APP_SLUG}[bot]@users.noreply.github.com"

echo "Git configuration complete"

# Subsequent git commands use github app credentials

# Work with the repository
git checkout main
echo "Current branch: $(git branch --show-current)"

# Make changes
echo "testing at $(date)" >> testdoc.md
git add testdoc.md
git status

echo "Committing changes..."
git commit -m "Testing github app permissions"

echo "Pushing to remote..."
git push origin main

echo "Operation completed successfully"

# Cleanup
rm -f .git/git-credentials
echo "Credentials cleaned up"
