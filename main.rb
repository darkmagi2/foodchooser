require 'sinatra'
require 'mysql2'
require 'sinatra/config_file'
require 'json'

config_file 'config.yml'
#establish connection
@db_pass = settings.db_pass
client = Mysql2::Client.new(:host => "localhost", :username => "sinatra", :password => @db_pass, :database => "choices")

get '/' do
  erb :entryform
end

get '/add' do
  erb :entryform
end
get '/items' do
  results = client.query("SELECT * FROM foodplaces")
  @items = results.to_a
  erb :table
end

post '/add' do
  client.query("insert into foodplaces (name, type, address) VALUES ('#{params[:name]}', '#{params[:type]}', '#{params[:address]}')")
  redirect '/items'
end

post '/random' do
  #selected_ids = [1,2,3] 
  #selected_ids = params[:selectedIds]
  selected_ids = JSON.parse(request.body.read)["selectedIds"]
  random_id = selected_ids.sample
  stmt = client.prepare("SELECT * FROM foodplaces WHERE id IN(?) ORDER BY RAND() LIMIT 1")
  results = stmt.execute(random_id)
  @selected_place = results.first
  content_type :json
  {success: true, selectedPlace: @selected_place}.to_json
  
end


