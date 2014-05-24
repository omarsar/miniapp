require 'rubygems'
require 'bcrypt'
require 'haml'
require 'sinatra'
require 'net/http'
require 'json'
require 'openssl'
require 'rack/ssl'

#Using Rack SSL
use Rack::SSL

#Helper Function to help with Sessions. Not implemented here! 
#enable :sessions
helpers do
  
  def login?
    if session[:name].nil?
      return false
    else
      return true
    end
  end
  
  def name
    return session[:name]
  end
  
end
 
get "/" do
  'SSL FTW!'
  haml :index
end

get "/users/create" do
  haml :signup
end
 
post "/users/create" do
  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

  # Setup URI for HTTP connection
  uri = URI('https://miniauth.herokuapp.com/api/v1/users')
  http = Net::HTTP.new(uri.host, uri.port)

  # Setup for HTTPS connection
  http.use_ssl = true
  # TODO: use VERIFY_PEER verification mode in production environment
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  # Setup HTTP request object
  req = Net::HTTP::Post.new(uri,
    initheader = {'Content-Type' =>'application/json'})
  req.body = {
    name: params[:name],
    email:params[:email],
    password:password_hash,
    bio:params[:bio],
    salt:password_salt
  }.to_json


	# Send request and wait for HTTP response
	res = http.request(req)
	"#{res.body}"
	#redirect COMPLETE

 
end
 
post "/users/login" do

	
	#Get the salt information for the specific user
	getemailurl = "https://miniauth.herokuapp.com/api/v1/users/"
	getemailurl2 = params[:email]
	getemailwhole = getemailurl + getemailurl2  
	response = Net::HTTP.get_response(URI(getemailwhole))
	salt = JSON.parse(response.body)['salt'].to_s
	password_hash = BCrypt::Engine.hash_secret(params[:password], salt)

	URLPART1 = "https://miniauth.herokuapp.com/api/v1/users/"
	URLPART2 = params[:email]
	URLPART3 = "/sessions"
	WHOLEURL = URLPART1 + URLPART2 + URLPART3

	uri = URI(WHOLEURL)
	http = Net::HTTP.new(uri.host, uri.port)

	 # Setup for HTTPS connection
	http.use_ssl = true
	  # TODO: use VERIFY_PEER verification mode in production environment
	http.verify_mode = OpenSSL::SSL::VERIFY_PEER

	req = Net::HTTP::Post.new(uri,
	initheader = {'Content-Type' =>'application/json'})
	req.body = {
	password:password_hash 
	}.to_json	

	res = http.request(req)
	"#{res.body}"

end

#Not used for this applicaiton (Session not supported)
get "/logout" do
  session[:name] = nil
  redirect "/"
end
 
__END__
@@layout
!!! 5
%html
  %head
    %title MiniApp
  %body
  =yield
@@index
-if login? #function not working because sessions are not enabled yet
  %h1= "Welcome #{name}!"
  %a{:href => "/logout"} Logout
-else
  %form(action="/users/login" method="post")
    %div
      %label(for="email")Username:
      %input#name(type="text" name="email")
    %div
      %label(for="password")Password:
      %input#password(type="password" name="password")
    %div
      %input(type="submit" value="Login")
      %input(type="reset" value="Clear")
  %p
    %a{:href => "/users/create"} Signup
@@signup
%p Enter your information (* required)!
%form(action="/users/create" method="post")
  %div
    %label(for="name")Username:
    %input#name(type="text" name="name")
  %div
    %label(for="email")Email*:
    %input#name(type="text" name="email")
  %div
    %label(for="password")Password:
    %input#password(type="password" name="password")
  %div
    %label(for="bio")Bio:
    %input#password(type="text" name="bio")
  %div
    %input(type="submit" value="Sign Up")
    %input(type="reset" value="Clear")