'use strict'

window.RecipeUI = angular.module 'RecipeUI', ['ui.bootstrap', 'ui.utils', 'ngCookies']

RecipeUI.factory 'Config', () ->
  {
    dialog_options: {
      backdropFade: true
      dialogFade: true
    }
  }

FoodData = ($http, $location, $cookies, $timeout) ->
  FoodData = {
    ordered_selected_foods: []
    selected_foods: {}
    food_amounts: {}
  }

  FoodData.add_color_and_select = (data, add=true) ->
    pk = data.pk
    data.bcolor = global.stringToColor(data.long_desc)
    data.pastel_color = global.pastelize data.bcolor
    FoodData.selected_foods[pk] = data
    # if you get weird errors with duplicate pks
    # ints and strings. remember to look here. grumble.
    if add
      # remove food from list if it is already there
      index = FoodData.ordered_selected_foods.indexOf(pk)
      if index > -1
        FoodData.ordered_selected_foods.splice index, 1
      # add food to front of list
      FoodData.ordered_selected_foods.unshift pk
      $location.hash FoodData.ordered_selected_foods.join ','

  FoodData.select_food = (pk, add=true) ->
    # add means to add to ordered_selected_foods
    $http(
      method: "GET"
      url: "/food/#{pk}"
    ).success (data) ->
      FoodData.add_color_and_select data, add

  FoodData.sync_from_location = () ->
    _.extend FoodData.food_amounts, $location.search()
    # can't do this elegantly bc we have strings and ints .. hrm ..
    #newosf = _.union(
    #  FoodData.ordered_selected_foods,
    #  $location.hash().split(',')
    #)
    #FoodData.ordered_selected_foods.splice 0
    # this is not idempotent .. hrm ...
    # only used in page creation with the little cookie mess.
    if $location.hash() isnt ""
      FoodData.ordered_selected_foods.push.apply(
        FoodData.ordered_selected_foods,
        (parseInt(i) for i in $location.hash().split(','))
      )

  FoodData.sync_to_location = () ->
    $location.search FoodData.food_amounts
    $location.hash FoodData.ordered_selected_foods.join ','

  FoodData.update_selected_foods = () ->
    $http(
      method: "GET"
      url: "/food"
      params:
        filter__pk__in: FoodData.ordered_selected_foods
    ).success((data) ->
      for food in data
        #console.log(food)
        FoodData.add_color_and_select food, false
    ).error(() ->
      console.log("ERROR!")
    )

  FoodData.save_food_cookies = () ->
    # can't just stringify the whole thing with the function?
    fd = {}
    fd.food_amounts = FoodData.food_amounts
    # quickly too big for cookies
    #fd.selected_foods = FoodData.selected_foods
    fd.ordered_selected_foods = FoodData.ordered_selected_foods
    $cookies.FoodData = JSON.stringify fd
    return

  FoodData.trash_food = (pk) ->
    delete FoodData.selected_foods[pk]
    delete FoodData.food_amounts[pk]
    #delete FoodData.selected_for_save[pk]
    index = FoodData.ordered_selected_foods.indexOf pk
    if index > -1
      FoodData.ordered_selected_foods.splice index, 1
      $location.hash FoodData.ordered_selected_foods.join ','

  FoodData.trash_all = () ->
    osf = FoodData.ordered_selected_foods.slice 0
    for pk in osf
      FoodData.trash_food pk

  ### userprofile stuff
  FoodData.save_wip = () ->
    hash = $location.url()
    if hash is window.userprofile.wip
      return
    $http(
      method: "POST"
      url: "/update-wip"
      data:
        hash: hash
    ).success (data) ->
      userprofile.wip = hash
  ###

  ###
  promise = null
  FoodData.timeout_save_wip = () ->
    # if we don't have a bmr, we haven't saved the profile.
    if window.userprofile.bmr is undefined
      return
    $timeout.cancel promise
    promise = $timeout FoodData.save_wip, 10000
###

  return FoodData
#FoodData.$inject = ['$http', '$location', '$cookies', '$timeout']
RecipeUI.factory 'FoodData', [
  '$http', '$location', '$cookies', '$timeout', FoodData]

#console.log FoodData

# TODO: Angular get attrs instead of hardcoding template - input-lg
lbsToGramsTemplate = """
<input type="text" class="input-lg" ng-model="lbs" placeholder="lbs to grams">
{{ convert_lbs_to_grams(lbs) }}
"""
RecipeUI.directive 'lbsToGrams', () ->
  {
    restrict: 'EA'
    template: lbsToGramsTemplate
    controller: ['$scope', ($scope) ->
      $scope.convert_lbs_to_grams = (lbs) ->
        grams = (lbs * 453.6).toFixed(2)
        if (isNaN grams) or (lbs is "") or (lbs is undefined)
          return ""
        else
          return "lbs = #{grams} grams"
    ]
  }


min_max_dict = {
    calories: [1200, 3000],
    protein: [60, 300],
    fat: [30, 200],
    carbohydrate: [200, 500],
    net_carbs: [180, 500],
    fiber: [20, 60],
    # starch, fructose, glucose are NA for most ..,
    #starch: 50,
    sugar: [20, 300],
    #glucose: 25,
    #fructose: 25,
    # minerals,
    calcium: [500, 2000],
    iron: [12, 20],
    magnesium: [350, 1500],
    phosphorus: [500, 3000],
    potassium: [2500, 7000],
    sodium: [2000, 6000],
    zinc: [12, 20],
    copper: [0.9, 10],
    flouride: [0, 500],
    manganese: [1.8, 10],
    selenium: [90, 1000],
    # vitamins,
    vit_a: [2000, 10000],
    vit_c: [75, 10000],
    vit_d: [200, 10000],
    vit_e: [12, 40],
    thiamin: [1.1, 5],
    riboflavin: [1.1, 5],
    niacin: [14, 350],
    pantothenic_acid: [5, 100],
    vit_b6: [1.3, 100],
    folate: [400, 1000],
    vit_b12: [2.4, 10],
    choline: [425, 3500],
    vit_k: [90, 2500],
    betaine: [25, 600],
    # protein - TBD,
    #amino_acids:,
    # fat,
    cholesterol: [0, 2000],
    trans_fat: [0, 3],
    saturated_fat: [3, 100],
    monounsaturated_fat: [3, 100],
    polyunsaturated_fat: [3, 100],
    omega3: [1, 30],
    omega6: [2, 50],
}

RecipeUI.directive 'nutrientVisualization', () ->


  return {
    restrict: 'E'
    # scope: true

    link: (scope, element, attrs) ->

      draw = () ->

        # returns abbreviated version of the food object
        data = scope.nutrient_contributions attrs.nutrient

        chart = d3.select(element[0])
        #chart.selectAll('*').remove()

        if data.length > 0

          chart = chart.append('svg')
              .attr('width', '100%')
              .attr('height', '480px')
          #.attr('class', 'span12').attr('class', 'chart')

          # TODO: I want the chart to completely fill the parent
          # without ever having a horizontal scrollbar
          # with the margin, that's not as easy as you would think.
          #width = element[0].parentElement.offsetWidth * .9
          #console.log chart
          #width = scope.windowWidth * .75  # span10
          #console.log width
          #console.log scope.windowWidth * .78
          #console.log element[0].parentElement.offsetWidth
          #console.log element
          #console.log element[0].parentElement.style.margin
          #width = element[0].parentElement.offsetWidth

          #console.log scope
          circle = chart.selectAll('circle').data(data)
          enter = circle.enter().append('circle')
              .attr "cy", 60
              .attr "cx", (d, i) -> i * 100 + 100
              .attr "r", (d) ->
                #console.log d
                #console.log attrs.nutrient
                #console.log d[attrs.nutrient]
                # scale per nutrient constant needed
                d.amt
              .attr "fill", (d) -> d.pastel_color
              # adding text element to circle
              #.attr "text", (d) -> d.desc
          circle.exit().remove();

          #move these calculations up front with the width/height decicions

          ###
          arr = (d.amt for d in data)
          total = _.reduce(arr, global.add_reduce_f, 0)
          #console.log(attrs.nutrient);
          min = min_max_dict[attrs.nutrient][0]
          x = d3.scale.linear().domain(
            [0, _.max([total, min])]
          ).range(
            [0 + "px", width + "px"]
          )

          chart.selectAll().data(
            data
          ).enter().append('div').style("width", (d) ->
            x _.max [d.amt, 0]
          ).style("background-color", (d) ->
            d.bcolor
          ).text (d) ->
            d.desc
          ###

      scope.timeout = null
      timeout_draw = () ->
        clearTimeout(scope.timeout)
        scope.timeout = setTimeout draw, 800

      scope.$watch 'food_amounts', timeout_draw, true
      scope.$watch 'selected_foods', timeout_draw, true
      scope.$watch 'windowWidth', timeout_draw, true
      #scope.$watch 'userprofile.min_max_dict', timeout_draw, true
  }


