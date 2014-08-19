import json
from django import http

from .models import Food


def all_food_json(request):
    # this is a select per food/nutrient.
    # MUST be cached
    # seriously, this take a half hour!
    # I think it should return about 36 megs
    # creating static file for unbacked D3 hacking
    res = json.dumps([
        food.as_dict() for food in
        Food.objects.all()
    ])
    return http.HttpResponse(res)
