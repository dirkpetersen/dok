#!/usr/bin/env bash
# aws-bedrock-user.sh
#
# Creates a least-privilege IAM user for AWS Bedrock access and outputs
# ready-to-paste credentials for ~/.aws/credentials.
#
# Usage:
#   Run directly in AWS CloudShell (no credentials needed — CloudShell is
#   already authenticated):
#
#     bash aws-bedrock-user.sh
#
#   Or paste the one-liner from the docs into CloudShell.

clear

# Define colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}             AWS Bedrock Setup Script                 ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Ask the user for their username
echo -ne "${CYAN}Enter your username: ${NC}"
read INPUT_NAME

# Clean the input (removes spaces, makes it lowercase) and add prefix
CLEAN_NAME=$(echo "$INPUT_NAME" | tr -d " " | tr "[:upper:]" "[:lower:]")
USERNAME="bedrock-${CLEAN_NAME}"

echo ""
echo -n "⏳ Creating IAM User ($USERNAME)... "
aws iam create-user --user-name "$USERNAME" > /dev/null 2>&1
echo -e "${GREEN}Done!${NC}"

echo -n "⏳ Attaching Bedrock access policy... "
aws iam attach-user-policy --user-name "$USERNAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess > /dev/null 2>&1
echo -e "${GREEN}Done!${NC}"

echo -n "⏳ Generating permanent access keys... "
KEY_OUTPUT=$(aws iam create-access-key --user-name "$USERNAME" 2>/dev/null)
ACCESS_KEY=$(echo "$KEY_OUTPUT" | jq -r ".AccessKey.AccessKeyId")
SECRET_KEY=$(echo "$KEY_OUTPUT" | jq -r ".AccessKey.SecretAccessKey")
echo -e "${GREEN}Done!${NC}"

echo ""
echo -e "${GREEN}✅ SUCCESS!${NC}"
echo -e "Copy the text inside the box below and save it to:"
echo -e "${CYAN}~/.aws/credentials${NC} on your local machine."
echo ""
echo "╭──────────────────────────────────────────────────────────────────╮"
echo "│ [bedrock]                                                        │"
echo "│ aws_access_key_id = $ACCESS_KEY                          │"
echo "│ aws_secret_access_key = $SECRET_KEY  │"
echo "╰──────────────────────────────────────────────────────────────────╯"
echo ""
