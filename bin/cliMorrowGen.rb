#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tty-prompt'
require 'tty-box'
require 'tty-spinner'
require_relative '../lib/MorrowGenService'

# Initialize the Service
service = MorrowGenService.new
prompt = TTY::Prompt.new

def clear_screen
  print "\033[2J\033[H"
end

loop do
  clear_screen
  prompt.say "\n"
  prompt.say 'Welcome to the Morrowind Character Generator', color: :cyan

  # 1. Inputs
  gender = prompt.select('Choose your gender:', %w[Male Female])
  race = prompt.select('Choose your race:', service.get_races)

  gen_method_choice = prompt.select('Choose Class Generation Method:',
                                    { 'Standard (Pick from pre-made list)' => :standard,
                                      'Smart Random (Lore-friendly custom class)' => :smart,
                                      'Pure Chaos (Random skills)' => :chaos })

  # 2. Class Generation Logic
  char_class = nil

  if gen_method_choice == :standard
    char_class = service.generate_class_draft(:standard)
  else
    # Generate Draft
    draft = service.generate_class_draft(gen_method_choice)

    # Preview
    clear_screen
    prompt.say '------ PREVIEW ------', color: :yellow
    puts service.preview_class(draft)
    prompt.say '---------------------', color: :yellow

    # Rename Option
    puts "\n"
    if prompt.yes?('Do you want to name this class?')
      custom_name = prompt.ask('Enter class name:')
      draft['name'] = custom_name unless custom_name.nil? || custom_name.strip.empty?
    end
    char_class = draft
  end

  # 3. Character Creation
  character = service.create_character(race, gender, char_class)

  # 4. Output
  box = TTY::Box.frame(
    border: :thick,
    title: { top_left: ' CHARACTER ' },
    padding: 1
  ) do
    character.to_s
  end

  print "\n"
  puts box
  print "\n"

  # 5. AI Backstory
  if prompt.yes?('Consult the Elder Scrolls? (Generate AI Backstory)')
    vibe = prompt.select("Choose the story's vibe:", %w[Gritty Humorous Mystical Tragic Heroic Random])
    vibe = %w[Gritty Humorous Mystical Tragic Heroic].sample if vibe == 'Random'

    origin = prompt.select('Choose their origin:',
                           ['Political Prisoner', 'Petty Thief', 'Dark Brotherhood Target', 'Failed Merchant',
                            'Heretic', 'Random'])
    if origin == 'Random'
      origin = ['Political Prisoner', 'Petty Thief', 'Dark Brotherhood Target', 'Failed Merchant',
                'Heretic'].sample
    end

    custom_input = prompt.ask('Any specific details to include? (Press Enter to skip):')

    spinner = TTY::Spinner.new('[:spinner] Consulting the Moth Priests...', format: :dots)
    spinner.auto_spin

    begin
      story = service.generate_backstory(character, vibe, origin, custom_input)
      spinner.success('(Done!)')

      story_box = TTY::Box.frame(
        title: { top_left: ' LORE ' },
        padding: 1,
        border: :thick,
        style: { border: { fg: :magenta } }
      ) do
        story.scan(/.{1,76}(?:\s|$)/).map(&:strip).join("\n")
      end

      puts "\n"
      puts story_box
      puts "\n"
    rescue StandardError => e
      spinner.error('(Failed!)')
      puts "Error connecting to the void: #{e.message}"
    end
  end

  break unless prompt.yes?('Generate another character?')
end

puts 'May you walk on warm sands.'
