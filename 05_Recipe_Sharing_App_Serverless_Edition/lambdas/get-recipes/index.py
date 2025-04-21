import json
import boto3
from typing import List, Dict
from decimal import Decimal
from boto3.dynamodb.conditions import Key
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('recipes')
class Ingredient(Dict):
    def __init__(self, id: int, description: str):
        super().__init__(id=id, description=description)
class Step(Dict):
    def __init__(self, id: int, description: str):
        super().__init__(id=id, description=description)
class Recipe(Dict):
    def __init__(self, id: str, title: str, ingredients: List[Ingredient], steps: List[Step], likes: int):
        super().__init__(id=id, title=title, ingredients=ingredients, steps=steps, likes=likes)
def lambda_handler(event, context):
    try:
        response = table.scan()
        recipes = response['Items']
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            recipes.extend(response['Items'])
        recipes_list = []
        for recipe in recipes:
            ingredients = [Ingredient(ing['id'], ing['description']) for ing in recipe['ingredients']]
            steps = [Step(step['id'], step['description']) for step in recipe['steps']]
            recipes_list.append(Recipe(recipe['id'], recipe['title'], ingredients, steps, recipe['likes']))
        print("--------")
        print(recipes_list)
        for i in recipes_list:
            print(type(i))
        return recipes_list
    except Exception as e:
        return {"message": f"Error retrieving recipes: {e}"}