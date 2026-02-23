#!/bin/bash

echo "=================================================="
echo "  AWS Leaderboard - Teardown Script"
echo "  This will DELETE all AWS resources created"
echo "  by setup.sh. This action cannot be undone."
echo "=================================================="
echo ""

# Get bucket name from user
echo "Enter the name of the S3 bucket you created (must end with -leaderboard): "
read bucket_name

if [[ ! "$bucket_name" == *-leaderboard ]]; then
  echo "Error: bucket name must end with -leaderboard"
  exit 1
fi

echo ""
echo "You are about to delete the following AWS resources:"
echo "  - S3 bucket:         $bucket_name"
echo "  - DynamoDB table:    LeaderBoard"
echo "  - Lambda functions:  get_all_leaderboard, get_top_gamers, submit_score"
echo "  - API Gateway:       LeaderBoardAPI"
echo "  - IAM roles/policies attached to Lambda"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Teardown cancelled."
  exit 0
fi

echo ""
echo "Starting teardown..."
echo ""

######################################### UNDEPLOY API GATEWAY #########################################

echo "Deleting API Gateway (LeaderBoardAPI)..."
sleep 1

# Get the API ID by name
API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='LeaderBoardAPI'].id" \
  --output text 2>/dev/null)

if [ -n "$API_ID" ] && [ "$API_ID" != "None" ]; then
  aws apigateway delete-rest-api --rest-api-id "$API_ID"
  echo "  ✓ API Gateway deleted (ID: $API_ID)"
else
  echo "  ⚠ LeaderBoardAPI not found — skipping"
fi

######################################### DELETE LAMBDA FUNCTIONS #########################################

echo ""
echo "Deleting Lambda functions..."
sleep 1

for fn in get_all_leaderboard get_top_gamers submit_score; do
  aws lambda delete-function --function-name "$fn" 2>/dev/null \
    && echo "  ✓ Lambda deleted: $fn" \
    || echo "  ⚠ Lambda not found: $fn — skipping"
done

######################################### DELETE IAM ROLES & POLICIES #########################################

echo ""
echo "Deleting IAM roles and policies..."
sleep 1

for role in LambdaDynamoDBReadRole LambdaDynamoDBWriteRole; do
  # Detach all managed policies first
  policies=$(aws iam list-attached-role-policies \
    --role-name "$role" \
    --query "AttachedPolicies[].PolicyArn" \
    --output text 2>/dev/null)

  for policy_arn in $policies; do
    aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn" 2>/dev/null
    echo "  ✓ Detached policy: $policy_arn from $role"
  done

  # Delete inline policies
  inline_policies=$(aws iam list-role-policies \
    --role-name "$role" \
    --query "PolicyNames[]" \
    --output text 2>/dev/null)

  for inline in $inline_policies; do
    aws iam delete-role-policy --role-name "$role" --policy-name "$inline" 2>/dev/null
    echo "  ✓ Deleted inline policy: $inline from $role"
  done

  # Delete the role
  aws iam delete-role --role-name "$role" 2>/dev/null \
    && echo "  ✓ IAM role deleted: $role" \
    || echo "  ⚠ IAM role not found: $role — skipping"
done

######################################### DELETE DYNAMODB TABLE #########################################

echo ""
echo "Deleting DynamoDB table (LeaderBoard)..."
sleep 1

aws dynamodb delete-table --table-name LeaderBoard 2>/dev/null \
  && echo "  ✓ DynamoDB table deleted: LeaderBoard" \
  || echo "  ⚠ DynamoDB table not found — skipping"

######################################### EMPTY & DELETE S3 BUCKET #########################################

echo ""
echo "Emptying and deleting S3 bucket ($bucket_name)..."
sleep 1

# Must empty the bucket before it can be deleted
aws s3 rm s3://$bucket_name/ --recursive 2>/dev/null \
  && echo "  ✓ S3 bucket emptied" \
  || echo "  ⚠ Could not empty bucket — it may already be empty"

aws s3api delete-bucket --bucket $bucket_name --region us-east-1 2>/dev/null \
  && echo "  ✓ S3 bucket deleted: $bucket_name" \
  || echo "  ⚠ S3 bucket not found — skipping"

######################################### RESET CONFIG FILES #########################################

echo ""
echo "Resetting config files to original state..."
sleep 1

# Reset s3_policy.json — replace bucket name back with placeholder
FILE_PATH_1="./resources/s3_policy.json"
if [ -f "$FILE_PATH_1" ]; then
  sed -i "s/$bucket_name/<bucket_name>/g" $FILE_PATH_1
  echo "  ✓ Reset: $FILE_PATH_1"
fi

# Reset put_bucket_policy.py
FILE_PATH_2="./resources/put_bucket_policy.py"
if [ -f "$FILE_PATH_2" ]; then
  sed -i "s/$bucket_name/<bucket_name>/g" $FILE_PATH_2
  echo "  ✓ Reset: $FILE_PATH_2"
fi

# Reset config.js — put null back in place of API Gateway URL
FILE_PATH_3="./resources/website/config.js"
if [ -f "$FILE_PATH_3" ]; then
  sed -i '0,/"https:\/\/[^"]*"/{s,"https://[^"]*",null,}' $FILE_PATH_3
  echo "  ✓ Reset: $FILE_PATH_3"
fi

######################################### CLEAN UP ENVIRONMENT VARIABLES #########################################

echo ""
echo "Cleaning up environment variables..."

sed -i "/bucket_url/d" ~/.bashrc
echo "  ✓ Removed bucket_url from ~/.bashrc"

######################################### DONE #########################################

echo ""
echo "=================================================="
echo "  Teardown complete! All AWS resources have"
echo "  been deleted and config files have been reset."
echo "  You can safely re-run setup.sh to start fresh."
echo "=================================================="
