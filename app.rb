require "sinatra"
require 'sinatra/flash'
require 'fog-aws'
require 'video_info'
require_relative "authentication.rb"
require_relative "models.rb"
require 'rubygems'
require 'stripe'



set :publishable_key, 'pk_test_jtKkZGQ3aijXByCqqPT8JBOV'
set :secret_key, 'sk_test_lyiw0Yi6Rb6SkH0QgvfuYTpp'

Stripe.api_key = settings.secret_key

VideoInfo.provider_api_keys = { youtube: 'AIzaSyAnYcD4cc4Q69mfaj5on34oglsEylcIPmI', vimeo: 'e6dc9a7f6e15ae51ee4fcc50909210b6' }

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil\

def youtube_embed(youtube_url)
	if youtube_url[/youtu\.be\/([^\?]*)/]
	  youtube_id = $1
	else
	  # Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
	  youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
	  youtube_id = $5
	end
  
	%Q{<iframe title="YouTube video player" width="640" height="390" src="https://www.youtube.com/embed/#{ youtube_id }" frameborder="0" allowfullscreen></iframe>}
end

get "/" do
	erb :index
end

get "/profile_test" do   #testing new profile page

	authenticate!
	@videos = Video.all
	@tags = Tag.all
	@comments = Comment.all
	@users = User.all
	@follows = Follow.all(follower_id: current_user.id)

	erb :profile_test
end 

get "/video/watch/:id" do   #Indidual video page TEST

	authenticate!
	@v=Video.all(id: params["id"])
	video = Video.first(id: params["id"])
	@tags = Tag.all(video_id: params["id"])
	@comments = Comment.all(video_id: params["id"])
	@users_p = User.all(id: video.user_id)
	@follows = Follow.all(follower_id: current_user.id)
	erb :watchVideo
end 

get "/posts/video/watch/:id" do   #copy of watchvidoe but boostrap forces /post maybe ?

	authenticate!
	@v=Video.all(id: params["id"])
	video = Video.first(id: params["id"])
	@tags = Tag.all(video_id: params["id"])
	@comments = Comment.all(video_id: params["id"])
	@users_p = User.all(id: video.user_id)
	@follows = Follow.all(follower_id: current_user.id)
	erb :watchVideo
end 


get "/users" do #shows all the users created
	authenticate!
	@users = User.all
	erb :users
end



get "/users/:id/videos" do		#show other users dashboard

	authenticate!
	@videos = Video.all(user_id: params["id"])
	@tags = Tag.all
	@comments = Comment.all
	@users = User.all
	@follows = Follow.all(follower_id: params["id"])

	erb :profile_test
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
	@follows = Follow.all(follower_id: current_user.id)
	erb :videos
end

get "/profile" do
	authenticate!
	@videos = Video.all(user_id: current_user.id)
	@tags = Tag.all
	@comments = Comment.all
	@follows = Follow.all(follower_id: current_user.id)
	erb :profile_test
	#erb :videos
end

post "/post/create" do      #grabs backend code in creating a new post
	
	authenticate!
	vid = Video.new

	if(current_user.pro==false && current_user.video_count<3) || (current_user.pro==true)

		if params["title"] && params["description"] && params["video_url"] && !params[:video] 

			video = VideoInfo.new(params["video_url"])
			
			vid.title = params["title"]
			vid.description = params["description"]
			vid.video_url = params["video_url"]
			vid.user_id = current_user.id
			vid.thumbnail_image=video.thumbnail_medium
			vid.save

			current_user.video_count+=1
			current_user.save
		end 

		if params[:video] && params[:video][:tempfile] && params[:video][:filename] &&  params["title"] && params["description"]  #if user uploads own video

					# create a connection
			connection = Fog::Storage.new({
				:provider                 => 'AWS',
				:aws_access_key_id        =>'AKIAJGOZPYPJ7CN7OUAQ',
				:aws_secret_access_key    => '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'
			})

			#file = params[:video][:filename]
			file       = params[:video][:tempfile]
			filename   = params[:video][:filename]

			bucket = connection.directories.new(:key => 'universal-dojo')
			
			file2 = bucket.files.create(
				:key    => filename,	#this is the FILE NAME uploaded to s3, still need to get filename from button 
				:body   => file,		# this is the actual file being uploaded
				:public => true
			)
				url=file2.public_url
				vid.s3_url=url
				vid.title=params["title"]
				vid.description=params["description"]
				vid.user_id=current_user.id
				vid.save

				current_user.video_count+=1
				current_user.save
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
		end
		
		redirect "/profile_test"

	else 
		erb :notPro

	
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
				c=current_user.video_count-1
				current_user.video_count=c
				current_user.save

				redirect back
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
		c = Comment.new
		c.user_id = current_user.id
		c.video_id = v.id
		c.text = params["text"]
		c.user_email = current_user.email
		c.save

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
			v.save
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
			v.save
		end
		dl.save
		redirect back
	end

end



get "/user/:id/follow" do	#follow someone
	authenticate!
	fllw = Follow.first(followed_id: params["id"], follower_id: current_user.id)
	@user_f = User.get(params["id"])

	if @user_f.id == current_user.id
		flash[:error] = "You can't follow yourself" 
		redirect back

	elsif fllw == nil
		f = Follow.new
		f.followed_id = params["id"]
		f.followed_email = @user_f.email
		f.follower_id = current_user.id
		f.follower_email = current_user.email	#emails are for display purposes
		f.save

		flash[:success] = "You requested to follow #{@user_f.email}"
		redirect back

	elsif fllw.accepted == false
		flash[:success] = "You already requested to follow #{@user_f.email}"
		redirect back
	else
		flash[:error] = "Already following #{@user_f.email}"
		redirect back
	end
end

#f = Follow.all
#f.destroy

get "/user/:id/notifications" do
	authenticate!
	
	@fl = Follow.all(followed_id: params["id"])


	erb :notifications
end

get "/user/request_accept/:f_id" do 	#accepts the request
	authenticate!
	fllw = Follow.get(params["f_id"])
	if fllw
		fllw.accepted = true
		fllw.save
		flash[:success] = "Follow request accepted"
		redirect back
	end
	#@users = User.get(params["id"])

end

get "/user/request_reject/:f_id" do 	
	authenticate!
	fllw = Follow.get(params["f_id"])
	if fllw 
		fllw.destroy
		flash[:success] = "Follow request rejected"
		redirect back
	end
	#@users = User.get(params["id"])

end

get "/upgrade"	do

	authenticate!
	erb :upgrade
end 

post "/charge" do
authenticate!
#	free_user!
	# Amount in cents
	@amount = 1000
  begin
		customer = Stripe::Customer.create(
			:email => 'customer@example.com',
			:source  => params[:stripeToken]
		)
		
		charge = Stripe::Charge.create(
			:amount      => @amount,
			:description => 'Sinatra Charge',
			:currency    => 'usd',
			:customer    => customer.id
		)
		
	

	rescue 
		erb :payment_error
	end

	current_user.pro = true
	current_user.save
	erb :charge
end 

get "/posts/search" do
	 authenticate!


#	@videos = Video.all(title: params["title"]) #only loads videos with substring of title

	@titles = Video.all

	#tests

	if @titles

		@tags = Tag.all
		@comments = Comment.all
		@users = User.all
		@follows = Follow.all(follower_id: current_user.id)
		erb :search

	end 

end 
