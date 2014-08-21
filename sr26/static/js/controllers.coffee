'use strict'

diet_to_array = {
  # arrays are carb, fat, protein
  'keto': [5, 75, 20]
  'zone': [40, 30, 30]
  'lowfat': [60, 10, 30]
  '80-10-10': [80, 10, 10]
  'custom': null
}
ensure_nutrients = [
  "calcium",
  "iron",
  "magnesium",
  "phosphorus",
  "potassium",
  "sodium",
  "zinc",
  "copper",
  "flouride",
  "manganese",
  "selenium",
  "vit_a",
  "vit_c",
  "vit_d",
  "vit_e",
  "thiamin",
  "riboflavin",
  "niacin",
  "pantothenic_acid",
  "vit_b6",
  "folate",
  "vit_b12",
  "choline",
  "vit_k",
  "betaine",
  "cholesterol",
  "trans_fat",
  "saturated_fat",
  "monounsaturated_fat",
  "polyunsaturated_fat",
  #"omega3",
  #"omega6",
]
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
  'vit_k',
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

MainFoodController = ($scope, $cookies, $location, FoodData) ->
  window.mfc_scope = $scope
  $scope.fs_toggle = true
  _.extend $scope, FoodData

  $scope.cookies = $cookies
  # take out FoodData state from the cookies, if we have them.
  if $cookies.FoodData?
    # add the cookies to FoodData and delete the cookie
    # for when logging in with social auth after having done some stuff.
    cFoodData = JSON.parse $cookies.FoodData
    FoodData.ordered_selected_foods.push.apply(
      FoodData.ordered_selected_foods, cFoodData.ordered_selected_foods)
    #_.extend FoodData.selected_foods, cFoodData.selected_foods
    _.extend FoodData.food_amounts, cFoodData.food_amounts
    delete $cookies.FoodData

  #else if $location.hash() isnt ""
    # if we have a hash in the url, just use that

  # no userprofile
  #else if window.userprofile.wip
    # take it from the userprofile on the server-side
    #$location.url window.userprofile.wip

  # some softwares will give us %23 for the "hash" part of the hash.
  # aint nobody got time fo dat
  $location.url $location.url().replace '%23', '#'
  # don't add a new browser history.
  $location.replace()
  # revisit: will there be different paths?
  # this is just to cleanup from social auth facebook redirect _=_
  $location.path("")
  # makes selected food state addressable
  # can't ever replace b/c want to pass it around in FoodData
  # we add the url stuff to the scope values
  # and then we add the scope values to the url stuff
  # in case it came from the cookie.
  FoodData.sync_from_location()
  FoodData.sync_to_location()
  #console.log "about to update_selected_foods"
  FoodData.update_selected_foods()

  $scope.$watch 'food_amounts', FoodData.timeout_save_wip, true
  $scope.$watch 'ordered_selected_foods', FoodData.timeout_save_wip, true
MainFoodController.$inject = ['$scope', '$cookies', '$location', 'FoodData']


FoodSearchController = ($scope, $http, FoodData) ->
  window.fsc_scope = $scope
  $scope.food_results = []
  $scope.ready_to_select = -1
  $scope.timeout = null

  $http(
    method: "GET"
    url: "/food"
    params:
      values: ["long_desc", "pk"]
      unlimited: "true"
  ).success (data) ->
    $scope.names_to_pk = {}
    $scope.names = []
    for pair in data
      pk = pair.pk
      name = pair.long_desc
      $scope.names.push name
      $scope.names_to_pk[name] = pk

  $scope.query_change = ->
    clearTimeout($scope.timeout)
    if $scope.query.length < 3
      $scope.food_results = []
      return
    $scope.timeout = setTimeout $scope.update_food_results, 800

  $scope.update_food_results = ->
    document.getElementById('search-list').scrollTop = 0
    $scope.ready_to_select = -1

    words = $scope.query.split(' ')
    filterf = (name) ->
      for word in words
        if name.toLowerCase().indexOf(word.toLowerCase()) < 0
          return false
      true
    names = _.filter($scope.names, filterf)

    res = []
    for name in names
      res.push {
        long_desc: name
        pk: $scope.names_to_pk[name]
      }
    $scope.food_results = res
    $scope.$apply()
    return

  $scope.query_key = ($event) ->
    $event.preventDefault()
    can_up = $scope.ready_to_select > 0
    can_down = $scope.ready_to_select < $scope.food_results.length - 1
    not_over = $scope.ready_to_select < $scope.food_results.length
    has_items = $scope.food_results.length > 0
    can_select = $scope.ready_to_select > -1 and not_over and has_items

    if $event.keyCode is 40
      key = "Down"
    else if $event.keyCode is 38
      key = "Up"
    else if $event.keyCode is 13
      key = "Enter"
    else
      $scope.ready_to_select = -1
      $scope.query = ""
      $scope.food_results = []
      document.getElementById('search-list').scrollTop = 0
      return

    if key is "Down"
      if can_down
        $scope.ready_to_select += 1
        # TODO: refine - no magic numbers
        if $scope.ready_to_select > 3
          document.getElementById('search-list').scrollTop += 20
      else
        # go to top
        $scope.ready_to_select = 0
        document.getElementById('search-list').scrollTop = 0
    else if key is "Up"
      if can_up
        $scope.ready_to_select -= 1
        # TODO: refine - no magic numbers
        if $scope.ready_to_select < $scope.food_results.length - 5
          document.getElementById('search-list').scrollTop -= 20
      else
        # go to bottom
        $scope.ready_to_select = $scope.food_results.length - 1
        document.getElementById('search-list').scrollTop = 9999999
    else if (key is "Enter" and can_select)
      selected = $scope.food_results[$scope.ready_to_select].pk
      $scope.select_food selected
      $scope.ready_to_select = -1
    else
      $scope.ready_to_select = -1

  $scope.mouseover = (idx) ->
    $scope.ready_to_select = idx
  $scope.mouseleave = (idx) ->
    $scope.ready_to_select = -1

  $scope.select_food = (pk) ->
    FoodData.select_food pk
    $scope.query = ""
    $scope.food_results = []
FoodSearchController.$inject = ['$scope', '$http', 'FoodData']


FoodTableController = ($scope, $http, $location, FoodData, Config) ->
  window.ftc_scope = $scope
  ftc_scope.loc = $location
  _.extend $scope, FoodData
  #_.extend $scope, ProfileData
  _.extend $scope, Config
  #_.extend $scope, FormHelper
  $scope.selected_for_save = {}
  $scope.toggle_weights = true
  $scope.save_as_recipe_modal = false
  $scope.recipe_form_data = {}
  $scope.recipe_posting = false
  $scope.trash_all_modal = false

  $scope.none_selected_for_save = () ->
    !_.any _.values $scope.selected_for_save

  $scope.all_selected_for_save = () ->
    for pk in $scope.ordered_selected_foods
      if not $scope.selected_for_save[pk]
        return false
    return true

  $scope.change_food_amount = () ->
    $location.search $scope.food_amounts

  $scope.add_weight = (pk, weight) ->
    amt = parseFloat($scope.food_amounts[pk] or 0)
    amt += parseFloat(weight)
    $scope.food_amounts[pk] = amt.toFixed 2
    $location.search $scope.food_amounts

  $scope.select_all_for_save = () ->
    for pk in $scope.ordered_selected_foods
      $scope.selected_for_save[pk] = true

  $scope.select_none_for_save = () ->
    for pk of $scope.selected_for_save
      $scope.selected_for_save[pk] = false

  $scope.save_as_recipe = () ->
    $scope.get_sum_selected_for_save()
    $scope.save_as_recipe_modal = true

  $scope.save_as_recipe_modal_close = () ->
    $scope.save_as_recipe_modal = false

  $scope.clear_recipe_form_data = () ->
    for key of $scope.recipe_form_data
      $scope.recipe_form_data[key] = ""

  $scope.get_sum_selected_for_save = () ->
    sum = 0
    for pk, selected of $scope.selected_for_save
      if selected
        sum += parseFloat $scope.food_amounts[pk]
    $scope.sum_selected_for_save = sum.toFixed 2

  ###
  $scope.post_recipe = () ->
    data = {}
    data.amounts = {}
    for pk, selected of $scope.selected_for_save
      if selected
        data.amounts[pk] = $scope.food_amounts[pk]
    _.extend data, $scope.recipe_form_data
    data.weight1 = $scope.sum_selected_for_save

    $scope.recipe_posting = true
    $http(
      method: "POST"
      url: urls.save_as_recipe
      data: data
    ).success (data) ->
      $scope.save_as_recipe_modal_close()
      $scope.consolidate_recipe(data)
      $scope.clear_recipe_form_data()
      $scope.recipe_posting = false
  ###

  ###
  $scope.consolidate_recipe = (data) ->
    for pk, selected of $scope.selected_for_save
      if selected
        $scope.trash_food parseInt pk
    FoodData.add_color_and_select data
    FoodData.food_amounts[data.pk] = $scope.sum_selected_for_save
    FoodData.sync_to_location()
    $scope.selected_for_save = {}
  ###

  $scope.btn_class_for_submit = (form) ->
    {
      'btn-danger': form.$invalid
      'btn-success': form.$valid
    }

  $scope.has_weight2 = () ->
    f = $scope.recipe_form_data.weight2_desc
    not_blank = f isnt undefined and f isnt ""
    if not not_blank
      delete $scope.recipe_form_data.weight2
    return not_blank
FoodTableController.$inject = [
  '$scope', '$http', '$location', 'FoodData', 'Config']


NutrientBreakdownController = ($scope, $http, $window, FoodData, Config) ->
  #_.extend $scope, ProfileData
  _.extend $scope, FoodData
  _.extend $scope, Config

  $scope.nutrition_page = 1
  $scope.nutrient_dialogs_open = {}

  $scope.windowWidth = $window.outerWidth;
  angular.element($window).bind 'resize', () ->
    $scope.windowWidth = $window.outerWidth;
    $scope.$apply 'windowWidth'

  $scope.nutrition_properties = PROPERTIES


  $scope.nutrient_total = (nutrient) ->
    fas = $scope.food_amounts
    total = 0
    for pk, d of $scope.selected_foods
      total += (d[nutrient] or 0) * (fas[pk] or 0) / 100
    return total.toFixed 1

  $scope.nutrient_contributions = (nutrient) ->
    fas = $scope.food_amounts
    ret = []

    # this might belong in css, I just want cronological left to right.
    revosf = $scope.ordered_selected_foods.slice(0).reverse()

    for pk in revosf
      # ordered_selected_foods gets initialized from the hash with everything
      # selected_foods db, gets updated 1 by 1 with select_food.
      # TODO: worry about browsers without hasOwnProperty?
      if $scope.selected_foods.hasOwnProperty pk
        d = $scope.selected_foods[pk]
        amt = (d[nutrient] or 0) * (fas[pk] or 0) / 100
        ret.push {
          pk: pk
          amt: amt
          desc: d.long_desc
          bcolor: d.bcolor
          pastel_color: d.pastel_color
        }
    return ret

  ###
  $scope.open_nutrient_detail = (nutrient) ->
    $http(
      method: "GET"
      url: urls.foods_highest_in
      params:
        nutrient: nutrient
    ).success (data) ->
      $scope.high_in_nutrient = data
      $scope.nutrient_dialogs_open[nutrient] = true

  $scope.page_changed = (page, nutrient) ->
    $http(
      method: "GET"
      url: urls.foods_highest_in
      params:
        nutrient: nutrient
        page: page
    ).success (data) ->
      $scope.high_in_nutrient = data
  ###

  $scope.close_nutrient_detail = (nutrient) ->
    $scope.nutrient_dialogs_open[nutrient] = false

  $scope.ensure_nutrient = (nutrient) ->
    ensure_nutrients.indexOf(nutrient) > -1
NutrientBreakdownController.$inject = [
  '$scope', '$http', '$window', 'FoodData', 'Config'
]

angular.module('RecipeUI').controller 'MainFoodController', MainFoodController
angular.module('RecipeUI').controller 'FoodSearchController', FoodSearchController
angular.module('RecipeUI').controller 'FoodTableController', FoodTableController
angular.module('RecipeUI').controller 'NutrientBreakdownController', NutrientBreakdownController
