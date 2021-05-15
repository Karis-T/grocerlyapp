require "sinatra"
require "tilt/erubis"
require "sinatra/content_for"
require "sinatra/reloader" if development?

configure do
  enable :sessions
  set :session_secret, 'secret'
end

configure do
  set :erb, :escape_html => true
end

CATAGORIES = [
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

def catagorize(grocery_list)
  by_catagory = {}
  CATAGORIES.each do |catagory|
    grocery_list.each do |ingredient|
      if by_catagory[catagory] && catagory == ingredient[:tag]
        by_catagory[catagory] << [ingredient[:amount], ingredient[:name]]
      elsif !(by_catagory[catagory]) && catagory == ingredient[:tag]
        by_catagory[catagory] = [[ingredient[:amount], ingredient[:name]]]
      end
    end
  end
  alphabetize(by_catagory)
end

def alphabetize(grocery_list)
  grocery_list.map do |catagory, items|
    items = items.sort_by { |ingredient| ingredient.last.downcase }
    [ catagory, items ]
  end.to_h
end

def titlize(string)
  string.split.map(&:capitalize).join(" ")
end

helpers do
  def find_ids(recipe)
    return recipe.keys if recipe.keys.all?{|ele| ele.is_a?(Integer)}
    id_array = recipe.keys
    id_array.select {|ele| ele.is_a?(Integer)}
  end
end

def next_id(recipe)
  id_array = find_ids(recipe)
  id_array.max || 0
end

def create_grocery(recipe_list, grocery_list)
  recipe_list.each do |name, recipe|
    if params[name]
      find_ids(recipe).each {|id| grocery_list  << recipe[id]}
    end
  end
end

def recipe_name_error(recipe_name)
  if session[:recipe_list].any? { |name, _| name == recipe_name }
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

def next_element_id(elements)
  max = elements.map { |todo| todo[:id] }.max || 0
  max + 1
end

before do
  session[:recipe_list] ||= {}
end

# go to the home page
get "/" do
  @recipe_list = session[:recipe_list]
  erb(:index)
end

# add a new recipe to the home page
post "/" do
  @recipe_name = titlize(params[:recipe_name])
  error = recipe_name_error(@recipe_name)
  if error
    session[:error] = error
    erb(:newrecipe)
  else
    session[:recipe_list][@recipe_name] = {}
    session[:success] = "recipe created!"
    redirect("/")
  end
end

# create a new recipe
get "/recipe/new" do
  erb(:newrecipe)
end

# go to the recipe's page
get "/recipe/:recipe_name" do
  @recipe_name = params[:recipe_name]
  @recipe = session[:recipe_list][@recipe_name]
  erb(:recipe)
end

# add ingredient to recipe
post "/recipe/:recipe_name/ingredient" do
  @recipe_name = params[:recipe_name]
  @recipe = session[:recipe_list][@recipe_name]
  id = next_id(@recipe) + 1
  error = ingredient_error(params[:amount], params[:name])
  if error
    session[:error] = error
    erb(:recipe)
  else
    @recipe[id] = {
      name: params[:name],
      amount: params[:amount] || "",
      tag: params[:tag] || "other"
    }
    session[:success] = "ingredient added!"
    redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
  end
end

#add method to the recipe
post "/recipe/:recipe/method" do
  @recipe_name = params[:recipe]
  @recipe = session[:recipe_list][@recipe_name]
  error = method_error(params[:method])
  if error
    session[:error] = error
    erb(:recipe)
  else
    @recipe[:method] = params[:method]
    session[:success] = "link added!"
    redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
  end
end

# delete method link recipe
post "/recipe/:recipe/method/delete" do
  @recipe_name = params[:recipe]
  @recipe = session[:recipe_list][@recipe_name]
  @recipe.delete(:method)
  session[:success] = "link deleted!"
  redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
end


#delete an ingredient
post "/recipe/:recipe/:id/delete" do
  id = params[:id].to_i
  @recipe_name = params[:recipe]
  session[:recipe_list][@recipe_name].delete(id)
  session[:success] = "ingredient deleted!"
  redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
end

#delete a recipe
post "/recipe/:recipe/delete" do
  @recipe_name = params[:recipe]
  session[:recipe_list].delete(@recipe_name)
  session[:success] = "recipe deleted!"
  redirect("/")
end

#page to upload and add an image to the recipe
get "/recipe/:recipe/image" do
  @recipe_name = params[:recipe]
  erb(:newimage)
end

#add an image to the recipe
post "/recipe/:recipe/image" do
  @recipe_name = params[:recipe]
  @recipe = session[:recipe_list][@recipe_name]
  error = image_error(params[:image])
  if error
    session[:error] = error
    erb(:newimage)
  else
    image = params[:image]
    session[:recipe_list][@recipe_name][:image] = image
    session[:success] = "image added!"
    redirect("/recipe/#{@recipe_name.gsub(" ", "%20")}")
  end
end

# delete grocery list
post "/grocery/delete" do
  session.delete(:grocery)
  session[:success] = "grocery list deleted!"
  redirect("/")
end

# add recipes to your grocery_list
get "/grocery/new" do
  @recipe_list = session[:recipe_list]
  erb(:newgrocery)
end

# view and edit grocery list
get "/grocery/edit" do
  @grocery_list = session[:grocery]
  erb(:groceryedit)
end

# compile selected recipes into grocery list
post "/grocery/edit" do
  session.delete(:grocery) if session[:grocery]
  @recipe_list = session[:recipe_list]
  @grocery_list = session[:grocery] = []
  create_grocery(@recipe_list, @grocery_list)
  redirect("/grocery/edit")
end

# add item to grocery list
post "/grocery/edit/add" do
  @grocery_list = session[:grocery]
  error = ingredient_error(params[:amount], params[:name])
  if error
    session[:error] = error
    erb(:groceryedit)
  else
    session[:grocery] << {
      name: params[:name],
      amount: params[:amount] || "",
      tag: params[:tag] || "other"
    }
    session[:success] = "item added!"
    redirect("/grocery/edit")
  end
end

# view catagorized grocery list
get "/grocery" do
  @grocery_finish = session[:grocery_finish]
  erb(:grocery)
end

# create catagorized grocery list
post "/grocery" do
  @grocery_list = session[:grocery]
  session[:grocery_finish] = catagorize(@grocery_list)
  redirect("/grocery")
end

# delete element from grocery list
post "/grocery/:idx/delete" do
  @grocery_list = session[:grocery]
  idx = params[:idx].to_i
  @grocery_list.delete_at(idx)
  redirect("/grocery/edit")
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

