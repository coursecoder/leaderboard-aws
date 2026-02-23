## Introduction
The purpose of this work is to develop and deploy a leaderboard for your game using the following AWS resources: S3, APIGateway, Lambda, IAM, and DynamoDB. The choice of a highly available, scalable, and secure serverless environment with massive economies of scale will have several benefits to the end user, including:
- low product pricing
- fast response time, and
- reliable uptime

## Leaderboard Architecture
![Playdough AWS Architecture](https://github.com/coursecoder/leaderboard-aws/blob/media/Playdough-AWS-Architecture.png)

## Project Organization
- **python_3 Folder:** This folder contains all python scripts that are used to build AWS infrastructure on the backend.
- **resources Folder:** This folder contains the initial setup script, teardown script, and the infrastructure for the frontend.
    - **website Folder:** This folder contains all the images and code necessary to build a functional game with leaderboard. Click the image below to see a live demo of what will be created.

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Visit%20Site-brightgreen?style=for-the-badge)](https://leaderboard-aws.s3.amazonaws.com/index.html)

## Requirements
- **AWS CLI:** See the [Getting started guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) in the *AWS CLI User Guide* for more information.
- **AWS Credentials:** Your AWS credentials need to have administrative privileges to IAM, S3, Lambda, API Gateway and DynamoDB. If you haven't setup AWS credentials before, [this resource from AWS](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html) is helpful.
- **AWS SDK for Python:** You will need to be running the latest Boto3 release. See the [Boto3 Quickstart](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html) for more information.

Install all Python dependencies with:
```
pip install -r requirements.txt
```

## Installation Instructions

### Step 1: Clone the repo
```
git clone https://github.com/coursecoder/leaderboard-aws.git
```

### Step 2: Run setup script
- Set permissions on the script so that you can run it, and then run it:
```
chmod +x ./resources/setup.sh && ./resources/setup.sh
```

- You will be asked to name your S3 bucket. Your bucket name must be appended with **-leaderboard** for the script to work. If you are not familiar with naming S3 buckets, see [Bucket Naming Rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html).

The setup script creates the following resources:

1. An S3 bucket with an associated bucket policy. The bucket contains the game website code.
2. An Amazon DynamoDB table populated with leaderboard data.
The leaderboard is already pre-seeded with 25 users (json file is resources/website/all_gamers.json). The leaderboard avatars are generated using the 3rd party API [DiceBear Avatars](https://avatars.dicebear.com/).
3. A REST API configured using Amazon API Gateway.
    - All game data is exposed at /leaderboard (GET)
    - Data for the top six players is exposed at /leaderboard/top_players (GET)
    - Score submission endpoint is exposed at /score/submit (POST).
4. Two Lambda functions are created
    - **get_all_leaderboard** function is used by the two GET endpoints to retrieve data from DynamoDB when invoked. There is a policy that gives the Lambda function permission to read data from DynamoDB.
    - **submit_score** function is used by the POST endpoint to put data to DynamoDB. The policy gives the Lambda function permission to update the DynamoDB data.

## Teardown Instructions

When you are finished with the project, run the teardown script to delete all AWS resources created by `setup.sh`. This is important to avoid ongoing AWS charges.

### Step 1: Run teardown script
```
chmod +x ./resources/teardown.sh && ./resources/teardown.sh
```

- You will be asked to confirm the name of your S3 bucket and presented with a list of all resources that will be deleted before proceeding.

The teardown script deletes the following resources in order:

1. **API Gateway** — deletes the `LeaderBoardAPI` REST API and all its endpoints.
2. **Lambda functions** — deletes `get_all_leaderboard`, `get_top_gamers`, and `submit_score`.
3. **IAM roles and policies** — detaches and deletes all roles and policies created during setup.
4. **DynamoDB table** — deletes the `LeaderBoard` table and all its data.
5. **S3 bucket** — empties and deletes the bucket and all website files.

The script also resets all local config files back to their original placeholder state so that `setup.sh` can be run again cleanly.

> **Note:** Teardown is permanent and cannot be undone. Make sure you no longer need the resources before running this script.
