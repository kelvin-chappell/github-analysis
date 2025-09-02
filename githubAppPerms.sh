#!/bin/bash

# GitHub app needs to have a client ID and a private key.
CLIENT_ID=$TEST_GITHUB_APP_CLIENT_ID
PRIVATE_KEY_FILE=$TEST_GITHUB_APP_PRIVATE_KEY_FILE
OWNER=$TEST_OWNER
REPO=$TEST_REPO

echo client Id "$CLIENT_ID"

# Generate JWT token for GitHub App authentication

# Create JWT payload
NOW=$(date +%s)
EXP=$((NOW + 600)) # 10 minutes expiration

JWT_HEADER='{"alg":"RS256","typ":"JWT"}'
JWT_PAYLOAD='{"iat":'$NOW',"exp":'$EXP',"iss":"'$CLIENT_ID'"}'

# Generate JWT (requires openssl and base64)
JWT_HEADER_B64=$(echo -n "$JWT_HEADER" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT_PAYLOAD_B64=$(echo -n "$JWT_PAYLOAD" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT_SIGNATURE=$(echo -n "${JWT_HEADER_B64}.${JWT_PAYLOAD_B64}" | openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
JWT_TOKEN="${JWT_HEADER_B64}.${JWT_PAYLOAD_B64}.${JWT_SIGNATURE}"

# Get installation info
INSTALLATION_INFO=$(gh api "/repos/${OWNER}/${REPO}/installation" --header "Authorization: Bearer ${JWT_TOKEN}")
APP_SLUG=$(echo "$INSTALLATION_INFO" | jq -r '.app_slug')
INSTALLATION_ID=$(echo "$INSTALLATION_INFO" | jq -r '.id')

USER_ID=$(gh api "/users/${APP_SLUG}[bot]" --jq .id)

# Get installation access token
ACCESS_TOKEN_RESPONSE=$(gh api "/app/installations/${INSTALLATION_ID}/access_tokens" --method POST --header "Authorization: Bearer ${JWT_TOKEN}")
ACCESS_TOKEN=$(echo "$ACCESS_TOKEN_RESPONSE" | jq -r '.token')

# Configure Git to use the access token for HTTPS authentication
git config --local --unset-all credential.helper store
git config --local credential.helper store
mkdir -p .git
echo "https://x-access-token:${ACCESS_TOKEN}@github.com" > .git/git-credentials
git config --local credential.helper "store --file=.git/git-credentials"

# Force HTTPS remote URL to ensure token is used
git remote set-url origin "https://github.com/${OWNER}/${REPO}.git"

git config --local user.name "${APP_SLUG}[bot]"
git config --local user.email "${USER_ID}+${APP_SLUG}[bot]@users.noreply.github.com"

# Subsequent git commands use github app credentials
git status
git checkout main
git commit githubAppPerms.sh -m "Testing github app permissions"
git push origin main
