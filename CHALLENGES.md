# Challenges — AWS Serverless Leaderboard

These challenges are designed to push your AWS skills further once you've completed the base project. They're organized by difficulty — start with Beginner and work your way up. Each one builds on real-world patterns used in production serverless systems.

> **Tip:** Before writing any code, open the AWS Console and explore the service you'll be working with. Understanding what you're building toward makes the implementation click faster.

---

## Beginner

### Challenge 1 — Add a Player Count to the Leaderboard Page
Display the total number of players in the DynamoDB table on the leaderboard UI.

**Skills practiced:** DynamoDB, Lambda, API Gateway, JavaScript

**Hints:**
- You can get the item count from a DynamoDB `scan` with `Select='COUNT'`
- Add a new attribute to the response returned by `get_all_leaderboard`
- Update the frontend to display it

---

### Challenge 2 — Add a Timestamp to Score Submissions
When a player submits a score, record the date and time it was submitted alongside their score in DynamoDB.

**Skills practiced:** Lambda, DynamoDB, Python

**Hints:**
- Use Python's `datetime` module to generate a timestamp
- Add it as a new attribute in the `submit_score` Lambda function
- Verify it appears in the DynamoDB Console after submitting a score

---

### Challenge 3 — Add CloudWatch Logging
Add meaningful log statements to both Lambda functions so you can monitor invocations and debug errors in CloudWatch.

**Skills practiced:** Lambda, CloudWatch, Python

**Hints:**
- Use Python's `print()` — Lambda automatically sends stdout to CloudWatch Logs
- Log the incoming event, the DynamoDB response, and any errors
- Open **CloudWatch → Log groups** in the console after invoking the function to verify

---

### Challenge 4 — Add Input Validation to Score Submission
Currently the `submit_score` Lambda accepts any payload. Add validation to reject submissions with missing fields or invalid data types.

**Skills practiced:** Lambda, Python, API Gateway error responses

**Hints:**
- Check that `gamer_name` is a non-empty string and `gamer_score` is a positive integer
- Return a `400 Bad Request` response with a helpful error message if validation fails
- Test it by sending a malformed POST request and verifying the error response

---

## Intermediate

### Challenge 5 — Add a DELETE Endpoint
Add a new API endpoint that allows a player record to be deleted from the leaderboard by `gamer_id`.

**Skills practiced:** Lambda, API Gateway, DynamoDB, IAM

**Steps to complete:**
1. Write a new Lambda function `delete_player` that calls `DynamoDB.delete_item`
2. Create a new IAM policy granting the function `dynamodb:DeleteItem` permission
3. Add a `DELETE /player/{gamer_id}` resource in API Gateway
4. Wire the resource to the new Lambda function and deploy

---

### Challenge 6 — Add Pagination to the Full Leaderboard
The current `view all` endpoint returns every player in one response. Add server-side pagination so the API returns players in pages of 10.

**Skills practiced:** DynamoDB scan/query, Lambda, API Gateway query parameters

**Hints:**
- DynamoDB supports pagination natively via `LastEvaluatedKey`
- Accept a `page` query parameter in API Gateway and pass it to Lambda
- Return a `next_page_token` in the response so the frontend can request the next page

---

### Challenge 7 — Add a Search Endpoint
Add a `GET /player/{gamer_name}` endpoint that looks up a specific player by name.

**Skills practiced:** DynamoDB, Lambda, API Gateway path parameters

**Hints:**
- API Gateway supports path parameters using `{param}` syntax in the resource path
- In Lambda, access it via `event['pathParameters']['gamer_name']`
- Use a DynamoDB `scan` with a `FilterExpression` to find matching players
- Think about why this is less efficient than querying by partition key — what would you change about the data model to make name lookups faster?

---

### Challenge 8 — Add a Lambda Layer for Shared Utilities
Refactor shared code (like response formatting and error handling) out of the individual Lambda functions and into a Lambda Layer.

**Skills practiced:** Lambda Layers, Python packaging, code reuse

**Why this matters:**
Lambda Layers let you share code and dependencies across multiple functions without duplicating them. This is the serverless equivalent of a shared library.

**Hints:**
- Create a `utils.py` file with shared helper functions
- Package it as a Lambda Layer using the correct directory structure (`python/utils.py`)
- Attach the layer to both Lambda functions and import from it

---

## Advanced

### Challenge 9 — Add API Key Authentication to the POST Endpoint
Protect the `POST /score/submit` endpoint with an API key so only authorized clients can submit scores.

**Skills practiced:** API Gateway usage plans, API keys, security

**Steps to complete:**
1. In API Gateway, create a Usage Plan and generate an API key
2. Require the API key on the `POST /score/submit` method
3. Update the frontend to pass the key in the `x-api-key` header
4. Test that requests without the key are rejected with a `403 Forbidden` response

> **Reflection:** API keys are a basic form of authentication. What are their limitations? What would you use instead for a production system with real users?

---

### Challenge 10 — Add a CloudFront Distribution
Put Amazon CloudFront in front of your S3 website to add HTTPS, caching, and a global CDN.

**Skills practiced:** CloudFront, S3, DNS, HTTPS

**Why this matters:**
S3 static websites don't support HTTPS on custom domains natively. CloudFront solves this and also dramatically improves load times by caching content at edge locations worldwide.

**Steps to complete:**
1. Create a CloudFront distribution pointing to your S3 bucket as the origin
2. Configure it to redirect HTTP to HTTPS
3. Set appropriate cache behaviors for HTML vs. static assets
4. Update your S3 bucket policy to only allow CloudFront to access it (not the public directly)

---

### Challenge 11 — Add a CI/CD Pipeline with GitHub Actions
Automate deployment of your Lambda function code using GitHub Actions so every push to `main` automatically deploys the latest version.

**Skills practiced:** GitHub Actions, CI/CD, AWS CLI, IAM

**Steps to complete:**
1. Create a GitHub Actions workflow file at `.github/workflows/deploy.yml`
2. Configure it to zip and upload updated Lambda code to S3 on push
3. Use `aws lambda update-function-code` to redeploy
4. Store your AWS credentials as GitHub Secrets — never hardcode them

> **Reflection:** What are the risks of automating deployments directly to production? How would you add a staging environment?

---

### Challenge 12 — Rewrite the Infrastructure as Code with AWS CDK
Replace the Python/Boto3 setup scripts with an AWS CDK app that defines all infrastructure as code.

**Skills practiced:** AWS CDK, Infrastructure as Code, Python

**Why this matters:**
The setup scripts in this project work, but they're imperative — they describe *how* to create resources step by step. AWS CDK is declarative — you describe *what* you want and CDK figures out how to create or update it. This is how infrastructure is managed at scale.

**Hints:**
- Install the CDK CLI: `npm install -g aws-cdk`
- Bootstrap your environment: `cdk bootstrap`
- Define your S3 bucket, DynamoDB table, Lambda functions, and API Gateway in a single CDK stack
- Run `cdk diff` to preview changes before deploying

---

## Completed a Challenge?

Push your changes to a new branch and open a pull request. Practice writing a clear PR description that explains what you built and why. This is exactly the workflow used on real engineering teams.

```bash
git checkout -b challenge/your-challenge-name
git add .
git commit -m "Challenge X: description of what you built"
git push origin challenge/your-challenge-name
```
