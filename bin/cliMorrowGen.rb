#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tty-prompt'
require 'tty-box'
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

  break unless prompt.yes?('Generate another character?')
end

puts 'May you walk on warm sands.'
