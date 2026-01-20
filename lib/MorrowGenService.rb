require_relative 'LoreGenerator'
require_relative 'CharacterGenerator'
require_relative 'CustomClassGenerator'
require_relative 'StatsGenerator'
require_relative 'ClassGenerator'
require_relative 'NameGenerator'
require_relative 'SkillsGenerator'

class MorrowGenService
  attr_reader :stats_gen, :class_gen, :name_gen, :custom_class_gen

  VIBES = %w[Gritty Humorous Mystical Tragic Heroic].freeze
  ORIGINS = ['Political Prisoner', 'Petty Thief', 'Dark Brotherhood Target', 'Failed Merchant', 'Heretic',
             'Unknown (let AI cook)'].freeze

  def initialize(data_dir = File.join(__dir__, '../data'))
    @stats_gen = StatsGenerator.new(
      File.join(data_dir, 'stats.yml'),
      File.join(data_dir, 'birthsigns.yml')
    )
    @class_gen = ClassGenerator.new(File.join(data_dir, 'classes.yml'))
    @name_gen = NameGenerator.new(File.join(data_dir, 'names.yml'))
    @custom_class_gen = CustomClassGenerator.new
  end

  def get_races
    @stats_gen.races.keys.map(&:capitalize).sort
  end

  def get_vibes
    VIBES
  end

  def get_origins
    ORIGINS
  end

  # Generates a class hash based on the method selected (Standard, Smart, Chaos)
  # Returns the class hash (draft)
  def generate_class_draft(method, custom_name = nil)
    case method
    when :standard
      @class_gen.get_random_class
    when :smart
      @custom_class_gen.generate_smart(custom_name)
    when :chaos
      @custom_class_gen.generate_chaos(custom_name)
    else
      raise "Unknown generation method: #{method}"
    end
  end

  # Formats the preview string for a custom class draft
  def preview_class(class_hash)
    @custom_class_gen.format_preview(class_hash)
  end

  # Finalizes and creates the Character object
  def create_character(race, gender, class_hash)
    Character.new(race, gender, @name_gen, @stats_gen, class_hash)
  end

  # Wraps the AI Lore Generation
  def generate_backstory(character, vibe, origin, custom_input)
    # Instantiate strictly when needed to avoid API checks on startup if unused
    lore_gen = LoreGenerator.new
    lore_gen.generate_story(character, vibe, origin, custom_input)
  end
end
