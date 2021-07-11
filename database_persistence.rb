require "pg"


CATEGORIES = [
  "fresh produce",
  "meat",
  "bakery",
  "eggs & dairy",
  "packaged goods",
  "drinks",
  "snacks",
  "herbs & spices",
  "intercontinental",
  "condiments",
  "canned / jarred goods",
  "cooking essentials",
  "personal care",
  "household goods",
  "frozen foods",
  "other"
]

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
        PG.connect(ENV['DATABASE_URL'])
      else
        PG.connect(dbname: "grocerly")
      end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def disconnect
    @db.close
  end

  def all_recipes
    sql = "SELECT name, image FROM recipes ORDER BY id;"
    result = query(sql)
    result.map do |tuple|
      [tuple["name"], {image: tuple["image"]}]
    end.to_h
  end

  def find_recipe(recipe_name)
    sql = "SELECT image, method FROM recipes WHERE name = $1;"
    result = query(sql, recipe_name).first
    {image: result["image"], method: result["method"]}
  end

  def create_new_recipe(recipe_name)
    sql = "INSERT INTO recipes (name) VALUES ($1);"
    query(sql, recipe_name)
  end

  def delete_recipe(recipe_name)
    sql = "DELETE FROM recipes WHERE name = $1;"
    query(sql, recipe_name)
  end

  def create_new_ingredient(recipe_name, name, amount, tag_id)
    recipe_id = find_r_id(recipe_name)
    sql = <<~SQL
    INSERT INTO ingredients (name, amount, tag_id, recipe_id)
    VALUES ($1, $2, $3, $4);
    SQL
    query(sql, name, amount, tag_id, recipe_id)
  end

  def view_ingredients(recipe_name)
    sql = select_ingredients(recipe_name)
    query(sql, recipe_name).map do |tuple|
      [tuple["id"].to_i, {amount: tuple["amount"], name: tuple["name"], tag: tuple["category"]}]
    end.to_h
  end

  def delete_ingredient_from_recipe(id)
    sql = "DELETE FROM ingredients WHERE id = $1;"
    query(sql, id)
  end

  def add_image_to_recipe(recipe_name, image)
    sql = "UPDATE recipes SET image = $1 WHERE name = $2;"
    query(sql, image, recipe_name)
  end

  def add_method_to_recipe(recipe_name, method)
    sql = "UPDATE recipes SET method = $1 WHERE name = $2;"
    query(sql, method, recipe_name)
  end

  def delete_method_from_recipe(recipe_name)
    sql = "UPDATE recipes SET method = NULL WHERE name = $1;"
    query(sql, recipe_name)
  end

  def add_recipes_to_grocery_list(recipe_name)
    sql = select_ingredients(recipe_name)
    query(sql, recipe_name).each do |tuple|
      add_item_to_grocery_list(tuple["amount"], tuple["name"], tuple["tag_id"])
    end
  end

  def view_grocery_list
    sql = "SELECT g.id, g.amount, g.name, t.category FROM groceries g JOIN tags t ON t.id = g.tag_id;"
    query(sql).map do |tuple|
      [tuple["id"].to_i, {amount: tuple["amount"], name: tuple["name"], tag: tuple["category"]}]
    end.to_h
  end

  def delete_grocery_list
    sql = "DELETE FROM groceries;"
    query(sql)
  end

  def add_item_to_grocery_list(amount, name, tag_id)
    sql = <<~SQL
    INSERT INTO groceries (amount, name, tag_id)
    VALUES ($1, $2, $3);
    SQL
    query(sql, amount, name, tag_id)
  end

  def find_t_id(tag)
    sql = "SELECT id AS t_id FROM tags WHERE category = $1;"
    query(sql, tag).first["t_id"].to_i
  end

  def delete_item_from_grocery_list(id)
    sql = "DELETE FROM groceries WHERE id = $1"
    query(sql, id)
  end

  def view_categorized_grocery_list
    sql = <<~SQL
    SELECT t.category, g.amount, g.name FROM groceries g
    JOIN tags t ON t.id = g.tag_id
    ORDER BY t.id;
    SQL
    result = query(sql).values.group_by{|row| row[0]}
    result.map do|category, arr|
      [ category, arr.map { |sub_arr| [sub_arr[1], sub_arr[2]] } ]
    end.to_h
  end

  private

  def select_ingredients(recipe_name)
    <<~SQL
    SELECT i.id, i.amount, i.name, t.category, i.tag_id FROM ingredients i
    JOIN tags t ON t.id = i.tag_id
    JOIN recipes r ON r.id = i.recipe_id
    WHERE r.name = $1;
    SQL
  end

  def find_r_id(recipe_name)
    sql = "SELECT id AS r_id FROM recipes WHERE name = $1;"
    query(sql, recipe_name).first["r_id"].to_i
  end
end
