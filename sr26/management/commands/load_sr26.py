import os
import csv

from django.core.management.base import BaseCommand

from sr26.models import (
    Food, FoodWeight, Nutrient, FoodNutrientAmount
)

data_path = os.path.join(
    os.path.dirname(__file__),
    "../../_data"
)

nutrient_def_path = os.path.join(data_path, "NUTR_DEF.txt")
food_desc_path = os.path.join(data_path, "FOOD_DES.txt")
nutrition_data_path = os.path.join(data_path, "NUT_DATA.txt")
weight_path = os.path.join(data_path, "WEIGHT.txt")


class Command(BaseCommand):
    help = 'Load the nutrition data'

    def handle(self, *args, **kwargs):
       
        with open(nutrient_def_path, 'rt', encoding="iso-8859-1") as datafile:
            reader = csv.reader(datafile, delimiter='^', quotechar='~')
            for row in reader:

                # VITD is not unique ... D2+D3
                name = row[2]
                if row[2] and Nutrient.objects.filter(tagname=row[2]):
                    # print "already", name
                    import time
                    name = name + str(hash(time.time()))

                print("creating nutrient", row, name)
                n, _ = Nutrient.objects.get_or_create(
                    id=row[0],
                    unit=row[1],
                    tagname=name,
                    desc=row[3]
                )

        with open(food_desc_path, 'rt') as datafile:
            reader = csv.reader(datafile, delimiter='^', quotechar='~')
            for row in reader:
                f, _ = Food.objects.get_or_create(
                    id=row[0],
                    long_desc=row[2],
                    short_desc=row[3],
                    common_name=row[4],
                    scientific_name=row[9],
                    percent_refuse=row[8] or 0,
                )

        for p in [nutrition_data_path]:
            with open(p, 'rt') as csvfile:
                reader = csv.reader(csvfile, delimiter='^', quotechar='~')
                for row in reader:
                    food = Food.objects.get(id=row[0])
                    nutrient = Nutrient.objects.get(id=row[1])
                    amount = row[2]
                    fna, _ = FoodNutrientAmount.objects.get_or_create(
                        food=food,
                        nutrient=nutrient,
                        amount=amount,
                    )
        
        with open(weight_path, 'rt', encoding="iso-8859-1") as csvfile:
            reader = csv.reader(csvfile, delimiter='^', quotechar='~')
            for row in reader:
                fw, _ = FoodWeight.objects.get_or_create(
                    food=Food.objects.get(pk=row[0]),
                    measure_desc=("%s %s" % (row[2], row[3])).strip(),
                    grams=row[4],
                )

        self.stdout.write('Successfully loaded nutrition data.')
