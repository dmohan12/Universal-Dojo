require 'data_mapper' # metagem, requires common plugins too.

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class User
    include DataMapper::Resource
    property :id, Serial
    property :email, Text
    property :password, Text
    property :profile_image_url, Text
    property :created_at, DateTime
    property :role_id, Integer, default: 1

    def administrator?
        return role_id == 0
    end

    def user?
        return role_id != 0
    end

    def login(password)
    	return self.password == password
    end
end

class Video
  include DataMapper::Resource
  property :id, Serial
  property :title, Text
  property :description, Text
  property :video_url, Text
  property :user_id, Integer
  property :date, DateTime
  property :like_counter, Integer
end

class Like
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Integer
  property :video_id, Integer
end

class Dislike
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Integer
  property :video_id, Integer

end

class Comment
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Integer
  property :video_id, Integer
  property :text, Text
  property :date, DateTime

end

class Tag
  include DataMapper::Resource
  property :id, Serial
  property :tag_name, Text
  property :video_id, Integer
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
User.auto_upgrade!
Video.auto_upgrade!
Like.auto_upgrade!
Dislike.auto_upgrade!
Comment.auto_upgrade!
Tag.auto_upgrade!
