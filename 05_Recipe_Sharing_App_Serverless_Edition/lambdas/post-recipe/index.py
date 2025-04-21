import json
import uuid
import boto3
from aws_lambda_powertools.utilities.parser import BaseModel
from typing import List, Optional
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('recipes')
class Ingredient(BaseModel):
    id: int
    description: str
class Step(BaseModel):
    id: int
    description: str
class Recipe(BaseModel):
    id:str
    title: str
    ingredients: List[Ingredient]
    steps: List[Step]
    likes: int
def lambda_handler(event, context):
  try:
    body = json.loads(event["body"])
    recipe = Recipe(
      id= str(uuid.uuid4()),
      title = body["title"],
      ingredients=body["ingredients"],
      steps=body["steps"],
      likes=body["likes"] 
      )
    table.put_item( Item={
            'id': str(uuid.uuid4()),
            'title': recipe.title,
            'ingredients':  [ingredient.dict() for ingredient in recipe.ingredients],
            'steps':  [steps.dict() for steps in recipe.steps],
            'likes': recipe.likes,
            }
            )
    return {"message": "Recipe created successfully"}
  except Exception as e:
    return {"message": f"Error creating recipe: {e}"}
def create_recipe(recipe: Recipe):
    try:
      table.put_item(Item={
      'id': str(uuid.uuid4()),
      'title': recipe.title,
      'ingredients':  [ingredient.dict() for ingredient in recipe.ingredients],
      'steps':  [steps.dict() for steps in recipe.steps],
      'likes': recipe.likes,
        })
      return {"message": "Recipe created successfully"}
    except Exception as e:
      return {"message": f"Error creating recipe: {e}"}