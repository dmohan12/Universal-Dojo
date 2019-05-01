require "sinatra"
require 'sinatra/flash'
require 'fog'
require_relative "authentication.rb"
require_relative "models.rb"


connection = Fog::Storage.new({
	:provider                 => 'AWS',
	:aws_access_key_id        => 'AKIAJLLPHO3SZWYNOMWA',
	:aws_secret_access_key    => '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'
	})


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

get "/users" do #shows all the users created
	authenticate!
	@users = User.all
	erb :users
end

get "/users/:id/videos" do		#show other users dashboard
	authenticate!
	@user = User.all(id: params["id"])
	@videos = Video.all(user_id: params["id"])
	@tags = Tag.all
	@comments = Comment.all
	erb :user_profile
end

get "/users/:id/delete" do	#delete users if you are admin
	authenticate!
	u = User.get(params["id"])
	v = Video.all(user_id: params["id"])
	c = Comment.all(user_id: params["id"])

	if current_user.role_id == 0
		u.destroy
		v.destroy
		c.destroy
		redirect "/users"
	else
		erb :noPermission
	end

end

get "/videos" do
	authenticate!
	@videos = Video.all#(user_id: current_user.id)
	@tags = Tag.all
	@comments = Comment.all
	@users = User.all
	@follows = Follow.all(your_id: current_user.id)
	erb :videos
end

get "/dashboard" do
	authenticate!
	@videos = Video.all(user_id: current_user.id)
	@tags = Tag.all
	@comments = Comment.all
	@users = User.all
	erb :dashboard
	#erb :videos
end

post "/post/create" do      #grabs backend code in creating a new post
	authenticate!
	vid = Video.new
	
	if params["title"] && params["description"] && params["video_url"]
		vid.title = params["title"]
		vid.description = params["description"]
		vid.video_url = params["video_url"]
		vid.user_id = current_user.id
		vid.save

		#adding tags
		if params["tag_name"]
			t = params["tag_name"].split(",")
			t.each do |tags|
				ta = Tag.new
				ta.tag_name = tags
				ta.video_id = vid.id
				ta.save
			end
			
		end
		redirect "/videos"
	end 
	
end

#post "/tags" do
#	erb :tags
#end

get "/post/new" do       #erb to postVideo
	authenticate!
	erb :postVideo
end 

get "/post/:id/delete" do   #delete function
	authenticate!
		v=Video.get(params["id"])
		#c=Comment.get(video_id: params["id"])

		if v
			if v.user_id==current_user.id || current_user.role_id == 0
				v.destroy
				#c.destroy
				redirect "/videos"
			else
				erb :noPermission
			end 
			#redirect "/videos"
		else
			erb :videoDNE
		end 
end 

get "/post/:id/comment" do 	#adds comment
	authenticate!
	v = Video.get(params["id"])
	if params["text"] 
		t = Comment.new
		t.user_id = current_user.id
		t.video_id = v.id
		t.text = params["text"]
		t.user_email = current_user.email
		t.save

	end
	
	redirect "/videos"
	

end

get "/post/:id/comment/delete" do	#will delete comment
	authenticate!



	redirect "/videos"
end

get "/post/like/:id" do   #like a video
	authenticate!

	lyke = Like.first(video_id: params["id"], user_id: current_user.id)
	if lyke != nil
		flash[:error] = "You already liked this post"
		redirect "/videos"

	else
		l = Like.new
		v = Video.get(params["id"])
		v.like_counter+=1
		v.save

		l.user_id=current_user.id
		l.video_id = params["id"]
		l.save
		redirect "/videos"
	end

end 


get "/user/:id/follow" do	#follow someone
	authenticate!
	fllw = Follow.first(their_id: params["id"], your_id: current_user.id)
	@u = User.get(params["id"])
	if fllw == nil
		f = Follow.new
		f.their_id = params["id"]
		f.your_id = current_user.id
		f.your_email = current_user.email	#emails are for display purposes
		f.their_email = @u.email
		f.save
		flash[:success] = "You followed #{@u.email}"
		redirect back
	else
		flash[:error] = "Already following #{@u.email}"
		redirect back
	end
end

#f = Follow.all
#f.destroy

get "/user/:id/notifications" do
	@users = User.all(id: current_user.id)
	@fllw = Follow.all(your_id: params["id"])

	
	erb :notifications
	

end

get "/user/:id/request_accept" do 	#isnt working
	authenticate!
	fllw = Follow.all(their_id: params["id"])
	@u = User.get(params["id"])

end

