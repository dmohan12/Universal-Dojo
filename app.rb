require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"
require_relative "models.rb"

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do
	erb :index
end

post "/videos" do
	@video = Video.new
	if params["title"] && params["video_url"]
		@video.title = params["title"]
		@video.description = params["description"]
		@video.video_url = params["video_url"]
		@video.user_id = current_user.id
	end
end

get "/videos" do
	authenticate!
	@videos = Video.all(id: current_user.id)
	#@tags = Tag.all
	erb :videos
end

get "/dashboard" do
	authenticate!
	erb :dashboard
end

post "/post/create" do      #grabs backend code in creating a new post
	authenticate!
	vid=Video.new
	#ta = Tag.new

	if params["title"] && params["description"] && params["video_url"]
		vid.title=params["title"]
		vid.description=params["description"]
		vid.video_url=params["video_url"]
		vid.save

		#adding tags
		if params["tag_name"]
			t = params["tag_name"].split(",")
			t.each do |tags|
				ta.tag_name = tags
				ta.video_id = vid.id
				ta.save
			end
			
		end
	end 

end

#post "/tags" do
#	erb :postVideo
#end

get "/post/new" do       #erb to postVideo
	authenticate!
	erb :postVideo
end 
