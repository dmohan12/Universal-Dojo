require 'sinatra'
require_relative "models.rb"

enable :sessions

set :session_secret, 'super secret'

get "/login" do
	
	erb :"authentication/login"
	
end


post "/process_login" do
	if params["email"] != nil && params["password"] !=nil
		email = params[:email]
		password = params[:password]

		user = User.first(email: email.downcase)

		if(user && user.login(password))
			session[:user_id] = user.id
			redirect "/"
		else
			flash[:error] = "Invalid login credentials"
			redirect back
		end
	else
		flash[:error] = "Invalid login credentials"
		redirect back
	end
end

get "/logout" do
	session[:user_id] = nil
	redirect "/"
end

get "/sign_up" do
	erb :"authentication/sign_up"
end


post "/register" do
	if params["email"] && params["password"]
	
	email = params[:email]
	password = params[:password]
	username = params[:username]


	u = User.new
	u.email = email.downcase
	u.password =  password
	u.username = username
	u.save

	session[:user_id] = u.id

	flash[:success] = "Successfully signed up"
	redirect "/"
	else
		flash[:error] = "Username or Password not correct"
		redirect back

	end
end

#This method will return the user object of the currently signed in user
#Returns nil if not signed in
def current_user
	if(session[:user_id])
		@u ||= User.first(id: session[:user_id])
		return @u
	else
		return nil
	end
end

#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end
