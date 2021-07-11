class SessionPersistence

  def initialize(session)
    @session = session
    @session[:recipe_list] ||= {}
  end

  def all_recipes
    @session[:recipe_list]
  end

  def find_recipe(recipe_name)
    all_recipes[recipe_name]
  end

  def create_new_recipe(recipe_name)
    all_recipes[recipe_name] = {}
  end

  def delete_recipe(recipe_name)
    all_recipes.delete(recipe_name)
  end

  def create_new_ingredient(id, recipe_name, name, amount, tag)
    find_recipe(recipe_name)[id] = {
      name: name,
      amount: amount || "",
      tag: tag || "other"
    }
  end

  def delete_ingredient_from_recipe(id, recipe_name)
    find_recipe(recipe_name).delete(id)
  end

  def add_image_to_recipe(recipe_name, image)
    find_recipe(recipe_name)[:image] = image
  end

  def add_method_to_recipe(recipe_name, method)
    find_recipe(recipe_name)[:method] = method
  end

  def delete_method_from_recipe(recipe_name)
    find_recipe(recipe_name).delete(:method)
  end

  def create_grocery_list
    @session[:grocery] = []
  end

  def add_recipes_to_grocery_list(recipe_name)
    all_recipes.each do |name, recipe|
      if recipe_name == name
        find_ids(recipe).each {|id| @session[:grocery] << recipe[id]}
      end
    end
  end

  def view_grocery_list
    @session[:grocery]
  end

  def delete_grocery_list
    @session.delete(:grocery)
  end

  def add_item_to_grocery_list(name, amount, tag)
    @session[:grocery] << {
      name: name,
      amount: amount || "",
      tag: tag || "other"
    }
  end

  def delete_item_from_grocery_list(idx)
    view_grocery_list.delete_at(idx)
  end

  def group_groceries_by_category
    @session[:grocery_finish] = categorize
  end

  def view_categorized_grocery_list
    @session[:grocery_finish]
  end

  def find_ids(recipe)
    return recipe.keys if recipe.keys.all?{|ele| ele.is_a?(Integer)}
    id_array = recipe.keys
    id_array.select {|ele| ele.is_a?(Integer)}
  end

  def next_id(recipe)
    id_array = find_ids(recipe)
    id_array.max || 0
  end

  private

  def categorize
    by_category = {}
    CATEGORIES.each do |category|
      view_grocery_list.each do |ingredient|
        if by_category[category] && category == ingredient[:tag]
          by_category[category] << [ingredient[:amount], ingredient[:name]]
        elsif !(by_category[category]) && category == ingredient[:tag]
          by_category[category] = [[ingredient[:amount], ingredient[:name]]]
        end
      end
    end
    alphabetize(by_category)
  end

  def alphabetize(grocery_list)
    grocery_list.map do |category, items|
      items = items.sort_by { |ingredient| ingredient.last.downcase }
      [ category, items ]
    end.to_h
  end
end
