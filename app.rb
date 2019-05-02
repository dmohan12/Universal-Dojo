require "sinatra"
require 'sinatra/flash'
require 'fog'
require "aws-sdk"
require 'video_info'
require_relative "authentication.rb"
require_relative "models.rb"
require 'rubygems'





VideoInfo.provider_api_keys = { youtube: 'AIzaSyAnYcD4cc4Q69mfaj5on34oglsEylcIPmI', vimeo: 'e6dc9a7f6e15ae51ee4fcc50909210b6' }


connection = Fog::Storage.new({
	:provider                 => 'AWS',
	:aws_access_key_id        => 'AKIAIONX34ZGTIXL5J4A',
	:aws_secret_access_key    => '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'
	})


if ENV['DATABASE_URL']
	S3_BUCKET = "instagram"
else
	S3_BUCKET = "instagram-dev"
end

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil\

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

		#video = VideoInfo.new(params["video_url"])
		
		vid.title = params["title"]
		vid.description = params["description"]
		vid.video_url = params["video_url"]
		vid.user_id = current_user.id
		#vid.thumbnail_image=video.thumbnail_medium
		vid.save
			
	elsif params[:video] && params[:video][:tempfile] && params[:video][:filename] &&  params["title"] && params["description"]

		file       = params[:video][:tempfile]
		filename   = params[:video][:filename]
		directory = connection.directories.create(
			:key    => "fog-demo-#{Time.now.to_i}", # globally unique name
			:public => true
		)
		file2 = directory.files.create(
			:key    => filename,
			:body   => file,
			:public => true
		)
		url = file2.public_url
		vid.video_url=url
		vid.description = parmas["description"]
		vid.title = params["title"]
		vid.save
			
	end

	#adding tags
	if params["tag_name"]
		t = params["tag_name"].split(",")
		t.each do |tags|
			ta = Tag.new
			ta.tag_name = tags
			ta.video_id = vid.id
			ta.save
		end
		redirect "/videos"
	end 
	
end


get "/post/new" do       #erb to postVideo
	authenticate!
	erb :postVideo
end 

get "/post/:id/delete" do   #delete function
	authenticate!
		v=Video.get(params["id"])
		c=Comment.all(video_id: params["id"])

		if v
			if v.user_id==current_user.id || current_user.role_id == 0
				v.destroy
				c.destroy
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
	
	redirect back
	

end

get "/post/:v_id/comment/:id/delete" do	#will delete comment
	authenticate!
	c = Comment.first(id: params["id"], video_id: params["v_id"])
	if c != nil
		c.destroy
		flash[:success] = "You removed the comment"

	else
		flash[:error] = "Cannot delete comment"
	end

	redirect back
end

get "/post/like/:id" do   #like a video
	authenticate!

	lyke = Like.first(video_id: params["id"], user_id: current_user.id)
	dlyke = Dislike.first(video_id: params["id"], user_id: current_user.id)

	if lyke != nil
		flash[:error] = "You already liked this post"
		redirect back

	else
		l = Like.new
		v = Video.get(params["id"])
		v.like_counter+=1
		
		v.save

		l.user_id=current_user.id
		l.video_id = params["id"]
		l.save
		if dlyke != nil
			dlyke.destroy
			v.dislike_counter-=1
		end
		redirect back
	end

end 

get "/post/dislike/:id" do
	authenticate!
	dlyke = Dislike.first(video_id: params["id"], user_id: current_user.id)
	lyke = Like.first(video_id: params["id"], user_id: current_user.id)
	if dlyke != nil
		flash[:error] = "You already disliked this post"
		redirect back

	else
		dl = Dislike.new
		v = Video.get(params["id"])
		
		v.dislike_counter+=1
		v.save

		dl.user_id=current_user.id
		dl.video_id = params["id"]
		if lyke != nil
			lyke.destroy
			v.like_counter-=1
		end
		dl.save
		redirect back
	end

end

l = Like.all
d = Dislike.all
l.destroy
d.destroy

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

