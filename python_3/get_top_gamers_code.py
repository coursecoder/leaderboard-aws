import boto3, json
from boto3.dynamodb.conditions import Key, Attr, Not

TABLE_NAME_STR = 'LeaderBoard'
INDEX_NAME_STR = 'special_GSI'
DDB = boto3.resource('dynamodb', region_name='us-east-1')
TABLE = DDB.Table(TABLE_NAME_STR)

def lambda_handler(event, context):
    # return top 5 gamers sorted by score descending
    print("Running query on index...")
    response = TABLE.query(
        IndexName=INDEX_NAME_STR,
        ScanIndexForward=False,  # descending order (highest score first)
        KeyConditionExpression=Key('special').eq(1),
        Limit=5
    )

    data = response['Items']

    # python returns non standard JSON
    # so we need to convert some data to integers
    for item in data:
        item['score_int'] = item.pop('score')
        if item.get('special') is not None:
            item['special_int'] = item.pop('special')
        item['tag_str_arr'] = item.pop('tags')
        item['rank_int'] = item.pop('rank')
        item['gamer_name_str'] = item.pop('gamer_name')
        item['gamer_id_str'] = item.pop('gamer_id')

        if item['score_int']:
            item['score_int'] = int(item['score_int'])
        if item['rank_int']:
            item['rank_int'] = int(item['rank_int'])
        if item.get('special_int') is not None:
            item['special_int'] = int(item['special_int'])

    return_me = {"leaderboard_item_arr": data}

    return return_me
