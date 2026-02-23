# leaderboard-aws

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Visit%20Site-brightgreen?style=for-the-badge)](https://leaderboard-aws.s3.amazonaws.com/index.html)

A hands-on AWS learning project that walks you through building and deploying a fully serverless game leaderboard from scratch. If you've been wanting to get practical experience with core AWS services, this is a great place to start.

## What You'll Learn

By completing this project you'll get hands-on experience with:

- **Amazon S3** — static website hosting and bucket policies
- **AWS Lambda** — serverless functions in Python
- **Amazon API Gateway** — building and deploying REST APIs
- **Amazon DynamoDB** — NoSQL database design and querying with GSI
- **AWS IAM** — roles, policies, and least-privilege access
- **AWS SDK for Python (Boto3)** — automating infrastructure with code

## Architecture

![Playdough AWS Architecture](https://github.com/coursecoder/leaderboard-aws/raw/media/Playdough-AWS-Architecture.png)

## Project Organization

- **python_3/** — Python scripts that build and configure all AWS infrastructure
- **resources/** — setup and teardown scripts plus the frontend game website
  - **website/** — the complete game and leaderboard frontend. See the [live demo](https://leaderboard-aws.s3.amazonaws.com/index.html) to see what you'll build.

## Requirements

Before you begin, make sure you have the following:

- **AWS CLI** — see the [Getting Started Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
- **AWS Credentials** — your credentials need administrative access to IAM, S3, Lambda, API Gateway, and DynamoDB. See [this AWS guide](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html) if you haven't set this up before
- **Python 3** with Boto3 — install dependencies with:

```bash
pip install -r requirements.txt
```

## Getting Started

### Step 1: Clone the repo

```bash
git clone https://github.com/coursecoder/leaderboard-aws.git
cd leaderboard-aws
```

### Step 2: Run the setup script

```bash
chmod +x ./resources/setup.sh && ./resources/setup.sh
```

You'll be prompted to name your S3 bucket. The name must end with **-leaderboard** (e.g. `mygame-leaderboard`). See [S3 Bucket Naming Rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) if you need guidance.

The setup script will automatically create:

1. **S3 bucket** — configured for static website hosting with an appropriate bucket policy. The game website files are uploaded here.
2. **DynamoDB table** — pre-seeded with 25 players and leaderboard data. Player avatars are generated using the [DiceBear API](https://avatars.dicebear.com/).
3. **API Gateway REST API** with three endpoints:
    - `GET /leaderboard` — returns all player data
    - `GET /leaderboard/top_players` — returns the top 5 players by score
    - `POST /score/submit` — submits a new score
4. **Lambda functions**:
    - `get_all_leaderboard` — reads all leaderboard data from DynamoDB
    - `submit_score` — writes new scores to DynamoDB
5. **IAM roles and policies** — scoped to give each Lambda function only the permissions it needs

## Teardown

When you're done, run the teardown script to delete all AWS resources and avoid ongoing charges:

```bash
chmod +x ./resources/teardown.sh && ./resources/teardown.sh
```

You'll be shown a list of everything that will be deleted and asked to confirm before anything is removed. The script also resets all local config files so you can run setup again cleanly if you want to start fresh.

> **Important:** AWS resources left running will incur charges. Always run teardown when you're finished experimenting.

## About This Project

This project was built as a practical learning resource for developers who want real, working experience with AWS services — not just theory. Everything is automated via Python and Bash scripts so you can focus on understanding what's being built rather than getting lost in manual console steps.

For full documentation and setup instructions visit the [GitHub repo](https://github.com/coursecoder/leaderboard-aws).
