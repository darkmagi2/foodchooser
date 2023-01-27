require 'sinatra'
require 'mysql2'

#establish connection
client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "z300l1l2", :database => "choices")

get '/' do
  erb :entryform
end

get '/items' do
  results = client.query("SELECT * FROM foodplaces")
  @items = results.to_a
  erb :table
end
