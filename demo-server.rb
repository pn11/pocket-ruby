require "sinatra"

require "./lib/pocket-ruby.rb"

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

Pocket.configure do |config|
  config.consumer_key = '10188-3565cd04d1464e6d0e64b67f'
end

get '/reset' do
  puts "GET /reset"
  session.clear
end

get "/" do
  puts "GET /"
  puts "session: #{session}"

  if session[:access_token]
    '
<ul>
<li/><a href="/add?url=http://getpocket.com">Add Pocket Homepage</a>
<li/><a href="/retrieve">Retrieve single item</a>
<li/><a href="/retrieve_newest">Retrieve newest items</a>
</ul>
    '
  else
    '<a href="/oauth/connect">Connect with Pocket</a>'
  end
end

get "/oauth/connect" do
  puts "OAUTH CONNECT"
  session[:code] = Pocket.get_code(:redirect_uri => CALLBACK_URL)
  new_url = Pocket.authorize_url(:code => session[:code], :redirect_uri => CALLBACK_URL)
  puts "new_url: #{new_url}"
  puts "session: #{session}"
  redirect new_url
end

get "/oauth/callback" do
  puts "OAUTH CALLBACK"
  puts "request.url: #{request.url}"
  puts "request.body: #{request.body.read}"
  result = Pocket.get_result(session[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = result['access_token']
  puts result['access_token']
  puts result['username']	
  # Alternative method to get the access token directly
  #session[:access_token] = Pocket.get_access_token(session[:code])
  puts session[:access_token]
  puts "session: #{session}"
  redirect "/"
end

get '/add' do
  client = Pocket.client(:access_token => session[:access_token])
  info = client.add :url => 'http://getpocket.com'
  "<pre>#{info}</pre>"
end

get "/retrieve" do
  client = Pocket.client(:access_token => session[:access_token])
  info = client.retrieve(:detailType => :complete, :count => 1)

  # html = "<h1>#{user.username}'s recent photos</h1>"
  # for media_item in client.user_recent_media
  #   html << "<img src='#{media_item.images.thumbnail.url}'>"
  # end
  # html
  "<pre>#{info}</pre>"
end

get "/retrieve_newest" do
  count = 20
  
  client = Pocket.client(:access_token => session[:access_token])
  info = client.retrieve(:detailType => :complete, :count => count)

  hash = info
#  puts hash.class

  html = "<body> Newest #{count} articles in my pocket<ul>"
  
  hash_list = hash["list"]
  puts "#of item is #{hash_list.size}"
#  puts hash_list
  
  hash_list.each do |k, v|
    hash_item = v
    title = hash_item["resolved_title"]
    url =  hash_item["resolved_url"]
    html += "<li/> <a href=#{url}> #{title} </a>"
    #    puts hash_item
  end

#  f = File.open("test.dat", "w")
#  json = JSON.generate(info)
#  puts json.class

  #    "<pre>#{info}</pre>"

  html += "</ul><a href=\"../\">back</a></body>"

  html
end
