require 'sinatra'
require 'mysql2'
require 'sinatra/config_file'

config_file 'config.yml'
#establish connection
@db_pass = settings.db_pass
client = Mysql2::Client.new(:host => "localhost", :username => "sinatra", :password => @db_pass, :database => "choices")

get '/' do
  erb :entryform
end

get '/items' do
  results = client.query("SELECT * FROM foodplaces")
  @items = results.to_a
  erb :table
end
