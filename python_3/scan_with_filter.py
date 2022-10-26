
import boto3, json
from boto3.dynamodb.conditions import Key
from boto3.dynamodb.conditions import Key, Attr, Not


def scan_gamers():
    
    DDB = boto3.resource('dynamodb', region_name='us-east-1')
    table = DDB.Table('LeaderBoard')

    response = table.scan(
                IndexName='special_GSI',
                # Once Cognito is implemented change the parameter below to hide unregistered users
                FilterExpression=(Attr('tags').contains('not registered')))
        
    data = response['Items']
    
    print (data)
 
if __name__ == '__main__':
    scan_gamers()
"""
Copyright @2021 [Amazon Web Services] [AWS]
    
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""
