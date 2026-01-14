#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tty-prompt'
require 'tty-box'
require 'tty-spinner'
require_relative '../lib/LoreGenerator'
require_relative '../lib/CharacterGenerator'
require_relative '../lib/CustomClassGenerator'

data_dir = File.join(__dir__, '../data')

sb = StatsGenerator.new(File.join(data_dir, 'stats.yml'), File.join(data_dir, 'birthsigns.yml'))
cb = ClassGenerator.new(File.join(data_dir, 'classes.yml'))
nd = NameGenerator.new(File.join(data_dir, 'names.yml'))
ccg = CustomClassGenerator.new

prompt = TTY::Prompt.new

def clear_screen
  print "\033[2J\033[H"
end

loop do
  clear_screen
  prompt.say "\n"
  prompt.say 'Welcome to the Morrowind Character Generator', color: :cyan

  # Gender
  gender = prompt.select('Choose your gender:', %w[Male Female])

  # Race
  race_options = sb.races.keys.map(&:capitalize).sort
  race = prompt.select('Choose your race:', race_options)

  # Class Generation
  gen_method = prompt.select('Choose Class Generation Method:',
                             { 'Standard (Pick from pre-made list)' => :standard,
                               'Smart Random (Lore-friendly custom class)' => :smart,
                               'Pure Chaos (Random skills)' => :chaos })

  char_class = nil

  case gen_method
  when :standard
    char_class = cb.get_random_class
  when :smart, :chaos
    # Generate Draft
    draft_class = gen_method == :smart ? ccg.generate_smart : ccg.generate_chaos

    # Show Preview
    clear_screen
    prompt.say '------ PREVIEW ------', color: :yellow
    puts ccg.format_preview(draft_class)
    prompt.say '---------------------', color: :yellow

    # Prompt for Name
    puts "\n"
    if prompt.yes?('Do you want to name this class?')
      custom_name = prompt.ask('Enter class name:')
      draft_class['name'] = custom_name unless custom_name.nil? || custom_name.strip.empty?
    end

    char_class = draft_class
  end

  # Initialize Character with the chosen/generated class
  character = Character.new(race, gender, nd, sb, char_class)

  # --- Output ---
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

  # --- AI Backstory Generation ---
  if prompt.yes?('Consult the Elder Scrolls? (Generate AI Backstory)')

    # Gather User Inputs
    vibe_choices = %w[Gritty Humorous Mystical Tragic Heroic Random]
    vibe = prompt.select("Choose the story's vibe:", vibe_choices)
    vibe = vibe_choices.sample if vibe == 'Random'

    origin_choices = ['Political Prisoner', 'Petty Thief', 'Dark Brotherhood Target', 'Failed Merchant', 'Heretic',
                      'Random']
    origin = prompt.select('Choose their origin:', origin_choices)
    origin = origin_choices.sample if origin == 'Random'

    custom_input = prompt.ask('Any specific details to include? (Press Enter to skip):')

    # Initialize Spinner
    spinner = TTY::Spinner.new('[:spinner] Consulting the Moth Priests...', format: :dots)
    spinner.auto_spin

    begin
      # Generate
      lore_gen = LoreGenerator.new
      story = lore_gen.generate_story(character, vibe, origin, custom_input)

      spinner.success('(Done!)')

      # Output
      story_box = TTY::Box.frame(
        # width: 80,
        title: { top_left: ' LORE ' },
        padding: 1,
        border: :thick,
        style: { border: { fg: :magenta } } # Purple border for "Mysticism"
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
