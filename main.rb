require 'rubygems'
require 'sinatra'
require 'mysql2'
require 'sinatra/config_file'
require 'json'
require 'connection_pool'

config_file 'config.yml'
#establish connection
@db_pass = settings.db_pass

DB_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  Mysql2::Client.new(
    host: 'localhost',
    username: 'sinatra',
    password: @db_pass,
    database: 'foodpicker'
  )
end

client = DB_POOL.with { |conn| conn }

get '/' do
  results = client.query("SELECT * FROM foodplaces")
  @items = results.to_a
  erb :table
end

get '/deleted' do
  results = client.query("SELECT * FROM deleted")
  @items = results.to_a
  erb :deleted
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
  redirect '/'
end

post '/random' do
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
    deleted_item = client.query("SELECT * FROM foodplaces WHERE id = #{id}").first
    client.query("INSERT INTO deleted (id, name, type, address) VALUES (#{deleted_item['id']}, '#{deleted_item['name']}', '#{deleted_item['type']}', '#{deleted_item['address']}')")
    client.query("DELETE FROM foodplaces WHERE id = #{id}")
    content_type :json
    { message: 'Entry deleted successfully' }.to_json
  rescue
    status 500
    { message: 'Error deleting entry' }.to_json
  end
end

post '/restore' do
  id = params[:id]
  begin
    deleted_item = client.query("SELECT * FROM deleted WHERE id = #{id}").first
    client.query("INSERT INTO foodplaces (id, name, type, address) VALUES (#{deleted_item['id']}, '#{deleted_item['name']}', '#{deleted_item['type']}', '#{deleted_item['address']}')")
    client.query("DELETE FROM deleted WHERE id = #{id}")
    content_type :json
    { message: 'Entry restored successfully' }.to_json
  rescue
    status 500
    { message: 'Error restoring entry' }.to_json
  end
end
