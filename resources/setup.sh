#!/bin/bash 

# get user input for bucket name
echo "Enter a name for your bucket. It must end with -leaderboard: "
read bucket_name

if [[ ! "$BUCKET_NAME" == *-leaderboard ]]; then
  echo "Error: bucket name must end with -leaderboard"
  exit 1
fi

######################################### BUILD #########################################

# create s3 bucket using the name provided and make it an environment variable
echo "Creating S3 bucket..."
sleep 2
bucket=`aws s3api create-bucket --bucket ${bucket_name} --region us-east-1 | xargs` >> ~/.bashrc
# create s3 bucket url 
echo export bucket_url="https://${bucket_name}.s3.amazonaws.com/index.html" >> ~/.bashrc

# configure the bucket as a static website
aws s3 website s3://${bucket_name}/ --index-document index.html

# update bucket policy with bucket name 
FILE_PATH_1="./resources/s3_policy.json"
sed -i "s/<bucket_name>/$bucket_name/g" $FILE_PATH_1
sed -i "s/<bucket_name>/$bucket_name/g" $FILE_PATH_1

# update python script with bucket name 
FILE_PATH_2="./resources/put_bucket_policy.py"
sed -i "s/<bucket_name>/$bucket_name/g" $FILE_PATH_2

# run script to attach bucket policy to S3 bucket
python3 ./resources/put_bucket_policy.py

# generate random playdough header image and download it
#img_url=$(python3 ./python_3/generate_header_img.py)
#wget --output-document=./resources/website/images/main_playdough.png $img_url

# copy files to S3 bucket
echo "Copying website files to S3 bucket..."
sleep 2
aws s3 cp ./resources/website s3://$bucket_name/ --recursive --cache-control "max-age=0"

# create DynamoDB table
python3 ./python_3/create_table.py

# batch upload gamers to DynamoDB table
python3 ./python_3/batch_put.py

# add Global Secondary Index to DynamoDB table
python3 ./python_3/add_gsi.py

#zip ./python_3/get_all_products_code.py 
# copy lambda functions to S3 bucket
aws s3 cp ./python_3/get_all_leaderboard_code.zip s3://$bucket_name/ --cache-control "max-age=0"
aws s3 cp ./python_3/submit_score_code.zip s3://$bucket_name/ --cache-control "max-age=0"

# create IAM role and get_all_leaderboard Lambda 
python3 ./python_3/create_iam_and_lambda.py

# create get_top_gamers Lambda
python3 ./python_3/create_top_gamers_lambda.py

######################################### DEPLOY #########################################
# create LeaderBoardAPI and create /leaderboard endpoint
python3 ./python_3/create_leaderboard_api.py

# create /leaderboard/top_gamer endpoint
python3 ./python_3/create_top_gamer_api.py

# create POST lambda
python3 ./python_3/create_submit_lambda.py

# create and deploy /score/submit POST endpoint
python3 ./python_3/create_submit_score_api.py


# get the base url for api gateway and update config file 
# update first occurrence of null in config file with api url 
FILE_PATH_3="./resources/website/config.js"
api_url=$(python3 ./python_3/get_api_url.py)
echo \"$api_url\"
sed -i "0,/null/{s,null,\"$api_url\",g}" $FILE_PATH_3 

# upload config.js file with API Gateway invoke url to S3 bucket
python3 ./python_3/update_config.py

echo "Your game website and leaderboard is now available on AWS!"
echo export bucket_url="https://${bucket_name}.s3.amazonaws.com/index.html" >> ~/.bashrc
