require "sinatra"
require 'sinatra/flash'
require 'fog'
require 'video_info'
require_relative "authentication.rb"
require_relative "models.rb"
require 'rubygems'





VideoInfo.provider_api_keys = { youtube: 'AIzaSyAnYcD4cc4Q69mfaj5on34oglsEylcIPmI', vimeo: 'e6dc9a7f6e15ae51ee4fcc50909210b6' }



#connection = Fog::Storage.new({
#	:provider                 => 'AWS',
#	:aws_access_key_id        => 'AKIAJLLPHO3SZWYNOMWA',
#	:aws_secret_access_key    => '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'
#	})

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

		# create a connection
connection = Fog::Storage.new({
	:provider                 => 'AWS',
	:aws_access_key_id        =>'AKIAJGOZPYPJ7CN7OUAQ',
	:aws_secret_access_key    => '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'
  })


     file = params[:video][:tempfile]
	#filename = params[:][:filename]
  
  directory = connection.directories.new(:key => 'universal-dojo')
filename = "C:/Users/NorwalkInn/Downloads/aws-s3-upload-vid.mp4"
#bucket.files.create(key: "dir/aws-s3-upload-vid.mp4", body: File.open(file_name), public: true)

file2 = directory.files.create(
	:key    => File.basename(file),                #this is the FILE NAME uploaded to s3, still need to get filename from button 
	:body   => file,   # this is the actual file being uploaded
	:public => true
  )


		url=file2.public_url
		vid.video_url=url
		vid.user_id=current_user.id
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
		
	redirect "/dashboard"
end

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
				redirect "/dashboard"
			else
				erb :noPermission
			end 
			redirect "/videos"
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

	lyke=Like.first(video_id: params["id"], user_id: current_user.id)
	

	if lyke != nil
		redirect "/dashboard"
	else 
		l=Like.new
		v=Video.get(params["id"])
		v.like_counter+=1
		v.save

		l.user_id=current_user.id
		l.video_id=params["id"]
		l.save
		redirect "/videos"
	end 

end 

