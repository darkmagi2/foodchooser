require 'rubygems'
require 'sinatra'
require 'mysql2'
require 'sinatra/config_file'
require 'json'

config_file 'config.yml'
#establish connection
@db_pass = settings.db_pass
client = Mysql2::Client.new(:host => "localhost", :username => "sinatra", :password => @db_pass, :database => "foodpicker")

get '/' do
  results = client.query("SELECT * FROM foodplaces")
  @items = results.to_a
  erb :table
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
  name = params[:name]
  type = params[:type]
  address = params[:address]
    
  # Validate the user input
  if name.nil? || name.strip.empty?
    return "Please enter a valid name, not a blank space"
  end

  if type.nil? || type.strip.empty?
    return "Please enter a valid type, not a blank space"
  end

  # Escape special characters in the input
  name = client.escape(params[:name])
  type = client.escape(params[:type])
  address = client.escape(params[:address])
  
  client.query("INSERT INTO foodplaces (name, type, address) VALUES ('#{name}', '#{type}', '#{address}')")
  #client.query("insert into foodplaces (name, type, address) VALUES ('#{params[:name]}', '#{params[:type]}', '#{params[:address]}')")
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

post '/delete' do
  id = params[:id]
  begin
    client.query("DELETE FROM foodplaces WHERE id = #{id}")
    content_type :json
    { message: 'Entry deleted successfully' }.to_json
  rescue
    status 500
    { message: 'Error deleting entry' }.to_json
  end
end


