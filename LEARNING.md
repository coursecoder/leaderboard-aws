# Learning Guide — AWS Serverless Leaderboard

This guide is designed to help you get more than just a working project out of this repo. Follow it alongside the setup steps in the README to build genuine understanding of each AWS service — not just familiarity with the commands.

---

## How to Use This Guide

Run each setup step, then **stop and verify** what was created in the AWS Console before moving on. The goal is to connect the code you ran to the infrastructure that appeared. Every section below includes:

- What the step does
- What to look for in the AWS Console
- Questions to deepen your understanding
- Common mistakes and how to spot them

---

## Stage 1 — S3: Static Website Hosting

**What's happening:**
The setup script creates an S3 bucket, applies a bucket policy, and uploads the game website files. S3 serves these files directly to the browser — no web server required.

**Verify it in the Console:**
1. Open the [S3 Console](https://s3.console.aws.amazon.com)
2. Find your bucket (ends in `-leaderboard`)
3. Click **Properties** → scroll to **Static website hosting** — it should be enabled
4. Click **Permissions** → **Bucket policy** — you should see a policy allowing public `GetObject`

**Questions to think about:**
- Why does a public website need a bucket policy? What would happen without it?
- What is the difference between making a bucket public vs. making individual objects public?
- S3 charges per GB stored and per GET request. For a high-traffic site, what are the cost implications of serving assets directly from S3?
- What would you add if you wanted HTTPS? (Hint: look up Amazon CloudFront)

**Common mistakes:**
- Bucket name doesn't end in `-leaderboard` — the script will fail with a validation error
- AWS credentials don't have S3 permissions — you'll see an `AccessDenied` error

---

## Stage 2 — DynamoDB: NoSQL Data Storage

**What's happening:**
The setup script creates a DynamoDB table called `LeaderBoard`, seeds it with 25 players, and adds a Global Secondary Index (GSI) so the top players can be queried efficiently.

**Verify it in the Console:**
1. Open the [DynamoDB Console](https://console.aws.amazon.com/dynamodb)
2. Click **Tables** → **LeaderBoard**
3. Click **Explore table items** — you should see 25 player records
4. Click **Indexes** — you should see `special_GSI` listed

**Questions to think about:**
- DynamoDB is a NoSQL database. How does its data model differ from a relational database like MySQL or PostgreSQL?
- What is a Global Secondary Index and why was one needed here? Could you query the top players without it?
- DynamoDB pricing is based on read/write capacity units. What is the difference between provisioned and on-demand capacity?
- The leaderboard data uses `gamer_id` as the partition key. Why is choosing a good partition key important in DynamoDB?

**Dig deeper:**
Open one of the player records and look at the attributes. Notice the `special` field set to `1`. This is what the GSI uses to identify top-gamer eligible players. Think about why this design decision was made.

**Common mistakes:**
- Running `batch_put.py` before the table is fully active — DynamoDB tables take a few seconds to become available after creation

---

## Stage 3 — IAM: Roles and Least-Privilege Access

**What's happening:**
The setup script creates an IAM role that grants Lambda permission to read from and write to DynamoDB — and nothing else. This is the principle of **least privilege**: give a service only the permissions it needs to do its job.

**Verify it in the Console:**
1. Open the [IAM Console](https://console.aws.amazon.com/iam)
2. Click **Roles** → find `Playdough-LambdaAccessToDynamoDB`
3. Expand the attached policies — you should see permissions scoped to DynamoDB only

**Questions to think about:**
- What would happen if you gave the Lambda function admin access instead of scoped DynamoDB access? Why is this a problem?
- IAM uses the concept of "trust policies" to define *who* can assume a role. Open the role's **Trust relationships** tab — what service is listed? Why does it need to be there?
- What is the difference between an IAM role and an IAM user?
- If you were building this for production, what additional restrictions might you add to the policy?

---

## Stage 4 — Lambda: Serverless Compute

**What's happening:**
Two Lambda functions are created: `get_all_leaderboard` (retrieves all players) and `submit_score` (writes a new score). The functions are packaged as `.zip` files, uploaded to S3, and deployed from there.

**Verify it in the Console:**
1. Open the [Lambda Console](https://console.aws.amazon.com/lambda)
2. You should see both functions listed
3. Click `get_all_leaderboard` → **Code** tab — you can read the function source directly here
4. Click **Configuration** → **Permissions** — verify the IAM role is attached

**Test it manually:**
1. Click **Test** in the Lambda console
2. Create a test event with an empty JSON payload `{}`
3. Run it — you should see leaderboard data returned in the execution result

**Questions to think about:**
- Lambda functions are stateless. What does that mean, and why does it matter for this use case?
- Lambda charges based on number of invocations and execution duration. How does this compare to running a dedicated server 24/7?
- What is a cold start? When would it be a problem?
- The function code uses `boto3.resource` to connect to DynamoDB — no credentials are passed in the code. How does the function authenticate? (Hint: it's the IAM role)

---

## Stage 5 — API Gateway: REST API

**What's happening:**
API Gateway creates a public REST API with three endpoints that trigger the Lambda functions. This is the layer that the game website calls to get and submit leaderboard data.

**Verify it in the Console:**
1. Open the [API Gateway Console](https://console.aws.amazon.com/apigateway)
2. Find `LeaderBoardAPI`
3. Click through the resource tree — you should see `/leaderboard`, `/leaderboard/top_gamer`, and `/score/submit`
4. Click **Stages** → find the deployed stage and copy the **Invoke URL**

**Test it in your browser:**
Paste the invoke URL + `/leaderboard` into your browser. You should get a JSON response with all player data.

**Questions to think about:**
- API Gateway acts as the "front door" to your Lambda functions. Why is this separation of concerns useful?
- The POST endpoint uses `mode: 'no-cors'` in the frontend fetch call. What is CORS and why does it matter for browser-based API calls?
- API Gateway supports REST APIs, HTTP APIs, and WebSocket APIs. When would you choose one over another?
- What would you add to this API if you wanted to protect the `POST /score/submit` endpoint from abuse?

---

## How It All Connects

Here's the full request flow when a player submits a score:

```
Browser (game.html)
    → POST /score/submit (API Gateway)
        → invoke submit_score (Lambda)
            → PutItem (DynamoDB)
```

And when the leaderboard loads:

```
Browser (index.html)
    → GET /leaderboard/top_gamer (API Gateway)
        → invoke get_all_leaderboard (Lambda)
            → Query with GSI (DynamoDB)
                → return top 5 players
```

Draw this out by hand. Tracing the full path from user action to database and back is one of the best ways to solidify your understanding of how these services work together.

---

## Challenges

Ready to go further? See [`CHALLENGES.md`](CHALLENGES.md) for a set of progressively harder extensions to this project.

---

## Troubleshooting

**`AccessDenied` errors**
Your AWS credentials don't have sufficient permissions. Verify your IAM user has admin access to S3, Lambda, API Gateway, DynamoDB, and IAM.

**`bucket already exists` error**
S3 bucket names are globally unique. Choose a different name ending in `-leaderboard`.

**Leaderboard shows no data**
The `config.js` file may not have been updated with your API Gateway URL. Check `resources/website/config.js` and verify the URL is set correctly.

**Lambda returns an error**
Open the Lambda Console → your function → **Monitor** → **View CloudWatch logs**. The full error will be there.

**API Gateway returns 5xx errors**
Usually means the Lambda function threw an exception. Check CloudWatch logs as above.
