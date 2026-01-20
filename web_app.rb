require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require_relative 'lib/MorrowGenService'
require 'securerandom'

enable :sessions
secret = ENV['SESSION_SECRET'] || SecureRandom.hex(64)
set :session_secret, secret

SERVICE = MorrowGenService.new

get '/' do
  @races = SERVICE.get_races
  erb :index
end

post '/generate' do
  gender = params[:gender]
  race = params[:race]
  method = params[:method].to_sym
  custom_name = params[:class_name]

  class_draft = SERVICE.generate_class_draft(method, custom_name)
  @character = SERVICE.create_character(race, gender, class_draft)

  session[:char_sheet] = @character.to_s

  erb :result
end

# Route for AI Lore Generation
post '/generate_lore' do
  content_type :json

  char_sheet = session[:char_sheet]
  return { error: 'No character found in session' }.to_json unless char_sheet

  payload = JSON.parse(request.body.read)

  # If the user selected 'Random', pick one from the Service's list.
  # Otherwise, use what they picked.
  vibe = payload['vibe']
  vibe = SERVICE.get_vibes.sample if vibe == 'Random'

  origin = payload['origin']
  origin = SERVICE.get_origins.sample if origin == 'Random'
  origin = 'Come up with some cool and fitting Origin for this character' if origin == 'Unknown (let AI cook)'

  puts origin
  details = payload['details']
  begin
    # 2. Call the generator with the resolved (concrete) values
    story = SERVICE.generate_backstory(char_sheet, vibe, origin, details)
    return { story: story }.to_json
  rescue StandardError => e
    return { error: e.message }.to_json
  end
end
