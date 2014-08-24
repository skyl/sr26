import json

from django import http
from django.db.models.sql.query import FieldError
from django.shortcuts import get_object_or_404

from .models import Food


def food(request):
    """
    Resource to interact with `Food` model.

    Examples:

        /food
            gets Food.objects.all() as a list of dicts, [0:10]

        /food?values=long_desc&values=pk&unlimited
            full list of long_desc, pk for all foods
            [
                {"pk": 1001, "long_desc": "Butter, salted"},
                ...
            ]

        /food?filter__pk__in=5&filter__pk__in=6
            Food.objects.filter(pk__in=[5,6]) as list of dicts
    """

    get = request.GET.copy()
    qs = Food.objects.all()

    # filters
    for key in filter(lambda q: q.startswith("filter__"), get.keys()):
        qs = qs.filter(**{key[8:]: get.getlist(key)})

    start = int(get.get("start", 0))
    end = start + int(get.get("limit", 10))
    if not ("unlimited" in get):
        qs = qs[start:end]

    if "values" in get:
        # /food?values_list=long_desc&values_list=pk
        #  {"long_desc": "Cheese, romano", "pk": 1038}
        try:
            return http.HttpResponse(json.dumps(list(
                qs.values(*get.getlist("values"))
            )))
        except FieldError as e:
            return http.HttpResponseBadRequest(e)

    res = json.dumps([food.as_dict() for food in qs])
    return http.HttpResponse(res)


def food_detail(request, pk):
    food = get_object_or_404(Food, pk=pk)
    return http.HttpResponse(json.dumps(food.as_dict()))
