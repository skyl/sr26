import json
import urllib
import logging
import datetime

from django.db import models

import sr26.constants as const
from sr26 import managers

logger = logging.getLogger(__name__)


PROPERTIES = [
    # macros
    'calories',
    'net_carbs',
    'fat',
    'protein',
    # carbohydrate
    'carbohydrate',
    'fiber',
    #'starch',
    'sugar',
    #'glucose',
    #'fructose',
    # minerals
    'calcium',
    'iron',
    'magnesium',
    'phosphorus',
    'potassium',
    'sodium',
    'zinc',
    'copper',
    'flouride',
    'manganese',
    'selenium',
    # vitamins
    'vit_a',
    'vit_c',
    'vit_d',
    'vit_e',
    'thiamin',
    'riboflavin',
    'niacin',
    'pantothenic_acid',
    'vit_b6',
    'folate',
    'vit_b12',
    #'vit_k',
    'choline',
    'betaine',
    # protein - TBD
    #'amino_acids',
    # fat
    'cholesterol',
    'trans_fat',
    'saturated_fat',
    'monounsaturated_fat',
    'polyunsaturated_fat',
    'omega3',
    'omega6',
]





class Nutrient(models.Model):
    id = models.AutoField(primary_key=True)
    unit = models.CharField(max_length=10)
    tagname = models.CharField(max_length=100)
    desc = models.CharField(max_length=50)

    class Meta:
        ordering = ['desc']

    def __unicode__(self):
        return "%s %s - %s" % (self.desc, self.unit, self.tagname)


class FoodNutrientAmount(models.Model):
    nutrient = models.ForeignKey('sr26.Nutrient')
    food = models.ForeignKey('sr26.Food')
    amount = models.FloatField(default=0)

    class Meta:
        ordering = ['-amount']
        unique_together = ['food', 'nutrient']


class FoodWeight(models.Model):
    """
    A common weight for a food; eg "1 tbsp butter=NN grams"
    <measure_desc> <food> = <grams>
    """
    food = models.ForeignKey('sr26.Food', related_name='weights')
    measure_desc = models.CharField(max_length=80)
    grams = models.FloatField()


class Food(models.Model):

    id = models.AutoField(primary_key=True)
    long_desc = models.CharField(max_length=200)
    short_desc = models.CharField(max_length=60, blank=True)
    common_name = models.CharField(max_length=100, blank=True)
    scientific_name = models.CharField(max_length=65, blank=True)

    percent_refuse = models.IntegerField(null=True, blank=True)
    nutrients = models.ManyToManyField(
        Nutrient,
        through="sr26.FoodNutrientAmount",
    )

    popularity = models.IntegerField(default=0)

    objects = managers.FoodManager()

    class Meta:
        ordering = ['-popularity']

    def __getattr__(self, tagname):
        if tagname.upper() not in const.tagnames:
            raise AttributeError('"%s" has no attr "%s"' % (self, tagname))

        # HRM. Performance.
        tagname = const.tagnames[tagname.upper()]
        #nutrient = Nutrient.objects.get(tagname=tagname)

        try:
            return FoodNutrientAmount.objects.get(
                food=self,
                nutrient__tagname=tagname,
                #nutrient=nutrient,
            ).amount
        except FoodNutrientAmount.DoesNotExist:
            return 0

    def __str__(self):
        return self.long_desc


    def full_description(self):
        """
        Put everything together.
        """
        full = [
            self.common_name,
            self.long_desc,
            self.short_desc,
            self.scientific_name,
        ]
        full = [n for n in full if n]
        return " - ".join(full)

    def as_dict(self):
        # fields and stuff without
        # _min_max
        _dict_properties = [
            'pk',
            'long_desc',
            'short_desc',
            'common_name',
            'scientific_name',
            'percent_refuse',
            'amino_acids',
            'ash',
        ]
        properties = PROPERTIES + _dict_properties

        d = {}
        for p in properties:
            d[p] = getattr(self, p, None)

        d['weights'] = []
        for w in self.weights.all():
            d['weights'].append([w.measure_desc, w.grams])
        return d

    # CARBOHYDRATE
    #########################

    @property
    def net_carbs(self):
        return round((self.carbohydrate or 0) - (self.fiber or 0), 2)

    # AMINOS
    ####################

    @property
    def amino_acids(self):
        r = []
        mapping = [
            (u'TRP_G', u'Tryptophan'),
            (u'THR_G', u'Threonine'),
            (u'ILE_G', u'Isoleucine'),
            (u'LEU_G', u'Leucine'),
            (u'LYS_G', u'Lysine'),
            (u'MET_G', u'Methionine'),
            (u'CYS_G', u'Cystine'),
            (u'PHE_G', u'Phenylalanine'),
            (u'TYR_G', u'Tyrosine'),
            (u'VAL_G', u'Valine'),
            (u'ARG_G', u'Arginine'),
            (u'HISTN_G', u'Histidine'),
            (u'ALA_G', u'Alanine'),
            (u'ASP_G', u'Aspartic acid'),
            (u'GLU_G', u'Glutamic acid'),
            (u'GLY_G', u'Glycine'),
            (u'PRO_G', u'Proline'),
            (u'SER_G', u'Serine'),
            (u'HYP', u'Hydroxyproline'),
        ]
        for k, v in mapping:
            r.append({
                "name": v.lower(),
                "amount": getattr(self, k),
            })
        return r

    # FATS
    #####################

    @property
    def omega3(self):
        return round((
            (self.F18D3 or 0) +
            #(self.F18D3CN3 or 0) +
            (self.F20D3N3 or 0) +
            (self.F20D5 or 0) +
            (self.F22D5 or 0) +
            (self.F22D6 or 0)
        ), 3)

    @property
    def omega6(self):
        return round((
            (self.F18D2 or 0) +
            (self.F18D3CN6 or 0) +
            (self.F20D2CN6 or 0) +
            (self.F20D3N6 or 0) +
            (self.F20D4N6 or 0)
        ), 3)
