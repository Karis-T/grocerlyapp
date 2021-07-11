-- tags 1 : M
-- an ingrdient / item can have many tags
-- only 1 tag can belong to an ingrdient / item

-- recipes 1 : M
-- a recipe can have many ingredients
-- an ingredient can only belong to 1 recipe

-- ingredients

DROP TABLE IF EXISTS groceries, recipes, ingredients, tags;

CREATE TABLE tags (
  id serial PRIMARY KEY,
  category varchar(50) NOT NULL
);

CREATE TABLE groceries(
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  amount varchar(20),
  tag_id integer NOT NULL DEFAULT 16 REFERENCES tags (id)
);

CREATE TABLE recipes(
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE,
  image text,
  method text
);

CREATE TABLE ingredients(
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  amount varchar(20),
  tag_id integer NOT NULL DEFAULT 16 REFERENCES tags (id),
  recipe_id integer REFERENCES recipes(id) ON DELETE CASCADE
);

INSERT INTO tags (category)
  VALUES
  ('fresh produce'),
  ('meat'),
  ('bakery'),
  ('eggs & dairy'),
  ('packaged goods'),
  ('drinks'),
  ('snacks'),
  ('herbs & spices'),
  ('intercontinental'),
  ('condiments'),
  ('canned / jarred goods'),
  ('cooking essentials'),
  ('personal care'),
  ('household goods'),
  ('frozen foods'),
  ('other');

INSERT INTO recipes (name, image, method)
VALUES ('French Toast',
        'https://www.jessicagavin.com/wp-content/uploads/2020/05/french-toast-11-1200.jpg',
        'https://www.mccormick.com/recipes/breakfast-brunch/quick-and-easy-french-toast'),
        ('Katsu Chicken Curry',
         'https://i8b2m3d9.stackpathcdn.com/wp-content/uploads/2020/04/Katsu_Curry_0858sq.jpg',
         'https://www.japanesecooking101.com/curry-and-rice-recipe/');

INSERT INTO ingredients (amount, name, tag_id, recipe_id)
     VALUES ('1/4 cup', 'milk', 4, 1),
            ('1/4 tsp', 'cinnamon', 8, 1),
            ('1', 'egg', 4, 1),
            ('4 slices', 'bread', 3, 1),
            ('1 tsp', 'butter', 4, 1),
            (NULL, 'maple syrup', 10, 1),
            ('2', 'carrots', 1, 2),
            ('2', 'onions', 1, 2),
            ('1', 'potato', 1, 2),
            ('1 box', 'japanese curry roux', 9, 2),
            ('1 box' , 'chicken tenders', 15, 2),
            ('1.5 cups', 'quinoa', 5, 2);