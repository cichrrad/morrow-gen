require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load'

class LoreGenerator
  BASE_URL = 'https://generativelanguage.googleapis.com/v1beta'

  def initialize
    @api_key = ENV['GEMINI_API_KEY']
    raise 'Missing GEMINI_API_KEY in .env file' unless @api_key

    # Dynamically find the correct model name to avoid 404s
    @model_name = fetch_available_flash_model
    puts "   (LoreGenerator connected to: #{@model_name})"
  end

  def generate_story(character, vibe, origin, custom_input)
    # Build the prompt
    prompt_text = build_prompt(character, vibe, origin, custom_input)

    # Prepare the Request
    # We use the model name we found during initialization
    url = "#{BASE_URL}/#{@model_name}:generateContent?key=#{@api_key}"
    uri = URI(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'

    # Build JSON Payload
    request.body = JSON.dump({
                               contents: [{ parts: [{ text: prompt_text }] }],
                               safetySettings: [
                                 { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_ONLY_HIGH' },
                                 { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_ONLY_HIGH' },
                                 { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_ONLY_HIGH' },
                                 { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' }
                               ]
                             })

    # Execute
    response = http.request(request)

    # Handle Response
    return "The Elder Scrolls are silent... (Error #{response.code}: #{response.message})" unless response.code == '200'

    data = JSON.parse(response.body)
    data.dig('candidates', 0, 'content', 'parts', 0, 'text')
  rescue StandardError => e
    "The connection to the void was severed: #{e.message}"
  end

  private

  def fetch_available_flash_model
    uri = URI("#{BASE_URL}/models?key=#{@api_key}")
    response = Net::HTTP.get_response(uri)

    return 'models/gemini-1.5-flash' unless response.code == '200'

    data = JSON.parse(response.body)
    # Find the first model containing 'flash'
    model = data['models'].find { |m| m['name'].include?('flash') }
    model ? model['name'] : 'models/gemini-1.5-flash' # Fallback
  end

  def build_prompt(character, vibe, origin, custom_input)
    <<~PROMPT
      You are a Loremaster of the Third Era (3E 427), an expert in the politics, geography, and cultures of Tamriel and Vvardenfell.

      I will provide you with a Character Sheet for a new Morrowind character.
      Your task is to write a short, cohesive biography (max 3 paragraphs) for them.#{' '}
      Utilize information about the character, such as their race and skills, to convey an interesting story.
      Dont be afraid of adult, tragic, and dark themes, if not directly opposed by the Vibe -- Tamriel is a tragic place.
      Make sure the story flows well and is believable. Make it so that the story can be used as basis for RP-ing the character in Morrowind.

      CONTEXT:
      - Vibe: #{vibe}
      - Origin: #{origin}
      - Additional Details: #{custom_input || 'None'}

      CHARACTER SHEET:
      #{character}

      CONSTRAINTS:
      1. Tone: The story must strictly adhere to the requested 'Vibe'.
      2. Ending: The story MUST end with the character being arrested and thrown into the brig of the Imperial Prison Ship, bound for Seyda Neen.
      3. Lore: Use specific terms, places, etc. from the lore of Tamriel to make the story more immersive (e.g., Great Houses, specific cities, divines, events and cultures).
      4. Do not include headers or markdown formatting (like **Bold**). Just the story text.
      5. Keep it under 300 words.
    PROMPT
  end
end
