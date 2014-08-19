from django.db import models
from django.db.models import Q
from django.db.models.query import QuerySet

from sr26 import constants

# TODO: complete and optimize
exclude_brand_query = Q(
        long_desc__icontains="General Mills"
    ) | Q(
        long_desc__icontains="KELLOGG"
    ) | Q(
        long_desc__icontains="POST"
    ) | Q(
        long_desc__icontains="KASHI"
    ) | Q(
        long_desc__icontains="MARS"
    ) | Q(
        long_desc__icontains="QUAKER"
    ) | Q(
        long_desc__icontains="MALT-O-MEAL"
    ) | Q(
        long_desc__icontains="Ralston"
    ) | Q(
        long_desc__icontains="Luna Bar"
    ) | Q(
        long_desc__icontains="NATURE'S PATH"
    ) | Q(
        long_desc__icontains="MORNINGSTAR FARMS"
    ) | Q(
        long_desc__icontains="WORTHINGTON"
    )


class FoodQueryset(QuerySet):

    def by_nutrient(self, tagname):
        tagname = tagname.upper()
        return self.filter(
            nutrients__tagname=constants.tagnames[tagname]
        ).order_by('foodnutrientamount')

    def brandless(self):
        return self.exclude(exclude_brand_query)

    def raw(self):
        return self.filter(long_desc__icontains=" raw")

    def sort_by_neg_a(self):
        return sorted(self, key=lambda f: f.VITA_IU)


class FoodManager(models.Manager):

    def get_queryset(self):
        return FoodQueryset(self.model, using=self._db)

    def by_nutrient(self, tagname):
        return self.get_query_set().by_nutrient(tagname)

    def brandless(self):
        return self.get_query_set().brandless()

    def raw(self):
        return self.get_query_set().raw()
