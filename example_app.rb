class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

   helper_method :current_user

   def current_user
     @current_user ||= User.find(session[:user_id]) if session[:user_id]
   end

   def require_user
     redirect_to '/login' unless current_user
   end

  def require_editor
  redirect_to '/' unless current_user.editor?
end

  def require_admin
    redirect_to '/' unless current_user.admin?
  end


end




class CuisinesController < ApplicationController

   def index
    @cuisines = Cuisine.all
  end

  def show
    @cuisine = Cuisine.find(params[:id])
    @recipes = @cuisine.recipes
  end

end



lass RecipesController < ApplicationController

  before_action :require_user, only: [:show, :edit, :update, :destroy]
before_action :require_editor, only: [ :edit]
  before_action :require_admin, only: [:show, :destroy]


  def show
    @recipe = Recipe.find(params[:id])
  end

  def edit
    @recipe = Recipe.find(params[:id])
  end

  def update
    @recipe = Recipe.find(params[:id])
      if @recipe.update(recipe_params)
        redirect_to @recipe
      else
        render 'edit'
      end
  end

  def destroy
    @recipe = Recipe.find(params[:id])
    @recipe.destroy
    redirect_to root_url
  end

  private
    def recipe_params
      params.require(:recipe).permit(:name, :ingredients, :instructions)
    end

end



class SessionsController < ApplicationController

  def new
  end

  def create
    puts params[:email]
    user = User.find_by_email(params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      session[:user_id] = user.id
      redirect_to root_url
    else
      redirect_to login_url
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end


end




class UsersController < ApplicationController

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
      if @user.save
        session[:user_id] = @user.id
        redirect_to root_url
      else
        redirect_to signup_url
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

end



class Cuisine < ActiveRecord::Base

  has_many :recipes

end


class Recipe < ActiveRecord::Base

  belongs_to :cuisine

end


class User < ActiveRecord::Base

  has_secure_password

  def editor?
  self.role == 'editor'
	end

  def admin?
    self.role == 'admin'
  end

end



class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password_digest
      t.string :role

      t.timestamps null: false
    end
  end
end




class CreateRecipes < ActiveRecord::Migration
  def change
    create_table :recipes do |t|
      t.string :name
      t.string :image
      t.text :ingredients
      t.text :instructions
      t.references :cuisine
      t.timestamps null: false
    end
  end
end



class CreateCuisines < ActiveRecord::Migration
  def change
    create_table :cuisines do |t|
      t.string :region
      t.string :image
      t.timestamps null: false
    end
  end
end



Rails.application.routes.draw do

  root 'cuisines#index'
  get 'signup' => 'users#new'
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  resources :users
  resources :cuisines, only: [:index, :show]
  resources :recipes, only: [:show, :edit, :update, :destroy]

  end




  <div class="cuisines">
  <div class="container">
    <% @cuisines.each do |cuisine|%>
      <div class="cuisine">
        <h2><%= cuisine.region %></h2>
        <img class="arrow" src="http://s3.amazonaws.com/codecademy-content/courses/rails-auth/img/arrow.svg" width="80" height="40">
        <p><%= link_to "View Recipes", cuisine_path(cuisine) %></p>
        <%= image_tag cuisine.image %>
      </div>
    <% end %>
  </div>
</div>





<div class="main">
  <h1 class="cuisine"><%= @cuisine.region %> Recipes</h1>
  <div class="container">
    <div class="recipes">
      <% @recipes.each do |recipe|%>
        <div class="recipe">
          <h2 class="recipe-name"><%= recipe.name %></h2>
          <img class="arrow" src="http://s3.amazonaws.com/codecademy-content/courses/rails-auth/img/arrow.svg" width="80" height="40">
          <p class="recipe-link"><%= link_to "Show Recipe", recipe_path(recipe) %></p>
          <%= image_tag recipe.image %>
        </div>
      <% end %>
    </div>

  </div>
</div>





<!DOCTYPE html>
<html>
  <head>
    <link href='http://fonts.googleapis.com/css?family=Montserrat:400,700' rel='stylesheet' type='text/css'>
    <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track' => true %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>
    <%= csrf_meta_tags %>
  </head>
  <body>

  <div class="header">
    <div class="container">

      <div class="nav">
        <% if current_user %>
          <ul>
            <li><%= current_user.email %></li>
            <li><%= link_to "Log out", logout_path, method: "delete" %></li>
          </ul>
        <% else %>
          <ul>
            <li><%= link_to "Log in", login_path %></a></li>
            <li><%= link_to "Sign up", signup_path %></a></li>
          </ul>
        <% end %>
      </div>

      <div class="logo">
      </div>

    </div>
  </div>

  <%= yield %>

  </body>
</html>





<div class="recipe-edit">
  <div class="container">
    <div class="img_container">
      <%= image_tag @recipe.image %>
    </div>

    <%= form_for(@recipe) do |f| %>
      <%= f.text_field :name %>
      <%= f.text_area :ingredients %>
      <%= f.text_area :instructions %>
      <%= f.submit "Update", :class => "form-btn" %>
    <% end %>

  </div>
</div>



<div class="recipe-show">
  <div class="container">
    <h2><%= @recipe.name %></h2>
    <img class="arrow" src="http://s3.amazonaws.com/codecademy-content/courses/rails-auth/img/arrow.svg" width="80" height="40">
    <div class="img_container">
      <%= image_tag @recipe.image %>
    </div>
    <div class="recipe-info">
      <p class="ingredients"><%= @recipe.ingredients %></p>
      <p class="instructions"><%= @recipe.instructions %></p>
    </div>

    <!-- Add links here -->
    <% if current_user && current_user.admin? %>
  <p class="recipe-delete"><%= link_to "Delete", recipe_path(@recipe), method: "delete" %><p>
<% end %>

		<% if current_user && current_user.editor? %>
  <p class="recipe-edit">
    <%= link_to "Edit Recipe", edit_recipe_path(@recipe.id) %>
  </p>
<% end %>
  </div>
</div>




<div class="login">
  <div class="container">
    <%= form_for(:session, url: login_path) do |f| %>
      <%= f.email_field :email, :placeholder => 'Email' %>
      <%= f.password_field :password, :placeholder => 'Password' %>
      <%= f.submit "Log in", :class => "form-btn" %>
    <% end %>
  </div>
</div>




<div class="login">
  <div class="container">
    <%= form_for :user, url: '/users' do |f| %>
      <%= f.text_field :first_name, :placeholder => 'First Name' %>
      <%= f.text_field :last_name, :placeholder => 'Last Name' %>
      <%= f.text_field :email, :placeholder => 'Email' %>
      <%= f.password_field :password, :placeholder => 'Password' %>
      <%= f.submit "Sign up", :class => "form-btn" %>
    <% end %>
  </div>
</div>









* {
  font-family: 'Montserrat', sans-serif;
  margin: 0;
  padding: 0;
}

body {
  background-color: #DAD8D2;
}

.header {
  background-color: #000;
  height: 300px;
  width: 100%;
}

.container {
  width: 100%;
}

.logo {
  background: url("http://s3.amazonaws.com/codecademy-content/courses/rails-auth/img/eatsinc-logo.svg");
  height: 100px;
  margin: 0 auto;
  position: relative;
  top: 140px;
  width: 220px;
}

.nav ul {
  list-style: none;
}

.nav ul li {
  color: #fff;
  display: block;
  float: left;
  height: 80px;
  line-height: 80px;
  text-align: center;
  width: 50%;
}

.nav ul li a {
  color: #fff;
  display: block;
  height: 100%;
  text-decoration: none;
  transition: background 0.5s, color 0.5s;
  width: 100%;
}

.nav ul li a:hover {
  color: #000;
  background-color: #fff;
  text-decoration: none;
  transition: background 0.5s, color 0.5s;
}

/*
  CUISINES & RECIPES
*/

div.cuisine, .recipe {
  height: 600px;
  overflow: hidden;
  position: relative;
  text-align: center;
}

h1.cuisine {
  background-color: #fff;
  height: 80px;
  font-weight: normal;
  line-height: 80px;
  text-align: center;
  width: 100%;
}

.cuisine img, .recipe img {
  margin: 0 auto;
  width: 100%;
}

.cuisine h2, .recipe h2 {
  background-color: rgba(0,0,0,0.8);
  color: #fff;
  display: block;
  font-size: 22px;
  font-weight: normal;
  height: 80px;
  line-height: 80px;
  margin: 0 auto;
  overflow: hidden;
  padding: 0 30px;
  position: absolute;
  text-overflow: ellipsis;
  top: 0;
  width: calc(100% - 60px);
  white-space: nowrap;
}

.cuisine a {
  background-color: #fff;
  bottom: 0;
  color: #000;
  display: block;
  height: 80px;
  line-height: 80px;
  position: absolute;
  right: 0;
  text-decoration: none;
  transition: background 0.5s, color 0.5s;
  width: 50%%;
}

.cuisine a:hover, .recipes .recipe-link a:hover, .recipes .recipe-edit a:hover, .recipe-show .recipe-edit a:hover, .recipe-show .recipe-delete a:hover, .recipe-edit form input.update-btn:hover, .login form input.form-btn:hover, .signup form input.form-btn:hover {
  color: #fff;
  background-color: #000;
  text-decoration: none;
  transition: background 0.5s, color 0.5s;
}

.recipes .recipe-link a {
  background-color: #fff;
  bottom: 0;
  color: #000;
  display: block;
  height: 80px;
  left: 0;
  line-height: 80px;
  position: absolute;
  text-decoration: none;
  transition: background 0.5s, color 0.5s;
  width: 50%;
}

.recipes .recipe-edit a {
  background-color: rgba(255,255,255,0.70);
  bottom: 0;
  color: #000;
  display: block;
  height: 80px;
  line-height: 80px;
  position: absolute;
  right: 0;
  text-decoration: none;
  transition: background 0.5s, color 0.5s;
  width: 50%;
}

img.arrow {
  left: 0;
  margin: 0 auto;
  position: absolute;
  top: 80px;
  right: 0;
  width: 80px;
}

/*
  RECIPE
*/

.recipe-show {
  position: relative;
  width: 100%;
}

.recipe-show h2 {
  background-color: rgba(0,0,0,0.8);
  color: #fff;
  display: block;
  font-size: 22px;
  font-weight: normal;
  height: 80px;
  line-height: 80px;
  margin: 0 auto;
  overflow: hidden;
  padding: 0 30px;
  position: absolute;
  text-align: center;
  text-overflow: ellipsis;
  top: 0;
  width: calc(100% - 60px);
  white-space: nowrap;
}

.img_container {
  height: 600px;
  overflow: hidden;
  text-align: center;
}

.img_container img {
  width: 100%;
}

.recipe-info {
  background-color: #000;
  display: block;
  float: left;
}

.ingredients {
  color: #fff;
  display: block;
  float: left;
  padding: 30px;
  width: calc(50% - 60px);
}

.instructions {
  background-color: #DAD8D2;
  display: block;
  float: left;
  font-family: Arial, sans-serif;
  font-size: 14px;
  height: 100%;
  line-height: 18px;
  padding: 30px;
  width: calc(50% - 60px);
}

.recipe-show .recipe-edit a {
  background-color: #fff;
  color: #000;
  display: block;
  height: 80px;
  line-height: 80px;
  position: absolute;
  right: 0;
  text-align: center;
  text-decoration: none;
  top: 520px;
  transition: background 0.5s, color 0.5s;
  width: 25%;
}

.recipe-show .recipe-delete a {
  background-color: #ed145b;
  color: #fff;
  display: block;
  height: 80px;
  line-height: 80px;
  position: absolute;
  left: 0;
  text-align: center;
  text-decoration: none;
  top: 520px;
  transition: background 0.5s, color 0.5s;
  width: 25%;
}

.recipe-edit form {
  margin: 0 auto;
  width: 100%;
}

.recipe-edit form input, .recipe-edit form textarea, .login form input, .signup form input {
  background-color: rgba(255,255,255,0.5);
  border: none;
  border-bottom: 4px solid #000;
  font-size: 16px;
  margin: 10px 30px 0;
  padding:30px;
  transition: border-bottom 0.5s;
  width: calc(100% - 120px);
}

.recipe-edit form textarea {
  resize: none;
}

.recipe-edit form input:focus, .recipe-edit form textarea:focus, .login form input:focus, .signup form input:focus {
  border:none;
  border-bottom: 4px solid #ed145b;
  box-shadow: 0 0;
  transition: border-bottom 0.5s;
  outline: none;
}

.recipe-edit form input.form-btn, .login form input.form-btn, .signup form input.form-btn {
  background-color: #fff;
  border: none;
  color: #000;
  cursor: pointer;
  height: 80px;
  line-height: 80px;
  margin: 10px 0 0;
  padding: 0;
  transition: background 0.5s, color 0.5s;
  width: 100%;
}

.login, .signup {
  margin: 0 auto;
  width: 400px;
}

.login form input, .signup form input {
  width: 280px;
}

.login form input.form-btn, .signup form input.form-btn {
  margin-left: 30px;
  width: 340px;
  transition: background 0.5s, color 0.5s;
}


/******
  MEDIA QUERIES
******/

@media screen and (max-width: 960px) {
  div.cuisine, .recipe, .img_container {
    height: 360px;
  }

  .recipe-show .recipe-edit a, .recipe-show .recipe-delete a {
    top: 280px;
  }
}

@media screen and (max-width: 580px) {
  div.cuisine, .recipe, .img_container {
    height: 260px;
  }

  .ingredients, .instructions {
    width: calc(100% - 60px);
  }

  .recipe-show .recipe-edit a, .recipe-show .recipe-delete a {
    top: 180px;
    width: 50%;
  }
}
