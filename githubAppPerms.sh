#!/bin/bash

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

# Generate JWT token for GitHub App authentication
NOW=$(date +%s)
EXP=$((NOW + 600)) # 10 minutes expiration

JWT_HEADER='{"alg":"RS256","typ":"JWT"}'
JWT_PAYLOAD='{"iat":'$NOW',"exp":'$EXP',"iss":"'$CLIENT_ID'"}'

# Generate JWT (requires openssl and base64)
JWT_HEADER_B64=$(echo -n "$JWT_HEADER" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT_PAYLOAD_B64=$(echo -n "$JWT_PAYLOAD" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT_SIGNATURE=$(echo -n "${JWT_HEADER_B64}.${JWT_PAYLOAD_B64}" | openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT_TOKEN="${JWT_HEADER_B64}.${JWT_PAYLOAD_B64}.${JWT_SIGNATURE}"

echo "Generated JWT token"

# Get installation info
echo "Getting installation info..."
INSTALLATION_INFO=$(gh api "/repos/${OWNER}/${REPO}/installation" --header "Authorization: Bearer ${JWT_TOKEN}")
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
    --header "Authorization: Bearer ${JWT_TOKEN}" \
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
