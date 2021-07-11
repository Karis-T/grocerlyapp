require "sinatra"
require "tilt/erubis"
require "sinatra/content_for"
require "sinatra/reloader" if development?

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

def titlize(string)
  string.split.map(&:capitalize).join(" ")
end

def recipe_name_error(recipe_name)
  if @storage.all_recipes.any? { |name, _| name == recipe_name }
    "recipe name must be unique"
  elsif !(2..50).cover?(recipe_name.length)
    "recipe name must be 2-50 characters"
  end
end

def ingredient_error(amount, name)
  if amount.length > 15
    "amount must be 1-15 characters"
  elsif !(1..20).cover?(name.length)
    "name must be 1-20 characters"
  end
end

def image_error(image)
  if !(image.match?(/\Ahttps/))
    "must be a secure image address"
  elsif !(image.match?(/.jpg\z|.png\z/))
    "image must be jpg or png"
  end
end

def method_error(method)
  if !(method.match?(/\Ahttps/))
    "link must be a secure url"
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

## recipes ##

# view recipe list (index page)
get "/" do
  @recipe_list = @storage.all_recipes
  erb(:index)
end

# add a new recipe to recipe list
post "/" do
  @recipe_name = titlize(params[:recipe_name])
  error = recipe_name_error(@recipe_name)
  if error
    session[:error] = error
    erb(:newrecipe)
  else
    @storage.create_new_recipe(@recipe_name)
    session[:success] = "recipe created!"
    redirect("/")
  end
end

# create a new recipe
get "/recipe/new" do
  erb(:newrecipe)
end

# view a recipe
get "/recipe/:recipe_name" do
  @recipe_name = params[:recipe_name]
  @recipe = @storage.find_recipe(@recipe_name)
  erb(:recipe)
end

# delete a recipe
post "/recipe/:recipe/delete" do
  @recipe_name = params[:recipe]
  @storage.delete_recipe(@recipe_name)
  session[:success] = "recipe deleted!"
  redirect("/")
end

## images ##

# upload an image for a recipe
get "/recipe/:recipe/image" do
  @recipe_name = params[:recipe]
  erb(:newimage)
end

# add/update uploaded image to the recipe
post "/recipe/:recipe/image" do
  @recipe_name = params[:recipe]
  @recipe = @storage.find_recipe(@recipe_name)
  error = image_error(params[:image])
  if error
    session[:error] = error
    erb(:newimage)
  else
    image = params[:image]
    @storage.add_image_to_recipe(@recipe_name, image)
    session[:success] = "image added!"
    redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
  end
end

## methods ##

# add a method to a recipe
post "/recipe/:recipe/method" do
  @recipe_name = params[:recipe]
  @recipe = @storage.find_recipe(@recipe_name)
  method = params[:method]
  error = method_error(params[:method])
  if error
    session[:error] = error
    erb(:recipe)
  else
    @storage.add_method_to_recipe(@recipe_name, method)
    session[:success] = "link added!"
    redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
  end
end

# delete a method from a recipe
post "/recipe/:recipe/method/delete" do
  @recipe_name = params[:recipe]
  @recipe = @storage.find_recipe(@recipe_name)
  @storage.delete_method_from_recipe(@recipe_name)
  session[:success] = "link deleted!"
  redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
end

## ingredients ##

# add an ingredient to a recipe
post "/recipe/:recipe_name/ingredient" do
  @recipe_name = params[:recipe_name]
  @recipe = @storage.find_recipe(@recipe_name)
  error = ingredient_error(params[:amount], params[:name])
  tag_id = @storage.find_t_id(params[:tag] || 'other')
  if error
    session[:error] = error
    erb(:recipe)
  else
    @storage.create_new_ingredient(@recipe_name, params[:name], params[:amount], tag_id)
    session[:success] = "ingredient added!"
    redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
  end
end


# delete an ingredient from a recipe
post "/recipe/:recipe/:id/delete" do
  id = params[:id].to_i
  @recipe_name = params[:recipe]
  @recipe = @storage.find_recipe(@recipe_name)
  @storage.delete_ingredient_from_recipe(id)
  session[:success] = "ingredient deleted!"
  redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
end

## grocery list ##

# create a new grocery list
get "/grocery/new" do
  @storage.delete_grocery_list
  erb(:newgrocery)
end

# add recipes to a grocery list
post "/grocery/edit" do
  @storage.all_recipes.each do |name, recipe|
    if params[name]
      @storage.add_recipes_to_grocery_list(params[name])
    end
  end
  redirect("/grocery/edit")
end

# view the grocery list
get "/grocery/edit" do
  erb(:groceryedit)
end

# delete the grocery list
post "/grocery/delete" do
  @storage.delete_grocery_list
  session[:success] = "grocery list deleted!"
  redirect("/")
end

# add item to grocery list
post "/grocery/edit/add" do
  error = ingredient_error(params[:amount], params[:name])
  tag_id = @storage.find_t_id(params[:tag] || 'other')
  if error
    session[:error] = error
    erb(:groceryedit)
  else
    @storage.add_item_to_grocery_list(params[:amount], params[:name], tag_id)
    session[:success] = "item added!"
    redirect("/grocery/edit")
  end
end

# delete item from grocery list
post "/grocery/:id/delete" do
  id = params[:id].to_i
  @storage.delete_item_from_grocery_list(id)
  session[:success] = "grocery item deleted!"
  redirect("/grocery/edit")
end

# view categorized grocery list
get "/grocery" do
  erb(:grocery)
end

# page not found
not_found do
  session[:error] = "page not found."
  redirect("/")
end

=begin
# recipe structure

session[:recipe_list] = {
  "turkey bolognese" => {
  id => {name: "onions", amount: "2 cups", tag: "fresh produce"},
  id =>  {id: 2, name: "carrots", amount: "3", tag: "fresh produce"}
  }
}
=end
