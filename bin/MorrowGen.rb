#!/usr/bin/env ruby
# frozen_string_literal: true

data_dir = File.join(__dir__, '../data')
require_relative '../lib/CharacterGenerator'

if ARGV.size < 2
  raise ArgumentError,
        "You must provide 2 arguments for gender and race (in order), you provided #{ARGV.size}:\n\nEx: \"ruby MorrowGen.rb male argonian\""
end

cb = ClassGenerator.new(File.join(data_dir, 'classes.yml'))
sb = StatsGenerator.new(File.join(data_dir, 'stats.yml'), File.join(data_dir, 'birthsigns.yml'))
nd = NameGenerator.new(File.join(data_dir, 'names.yml'))

# Default to standard random class for non-interactive mode
random_class = cb.get_random_class

C = Character.new(ARGV[1], ARGV[0], nd, sb, random_class)
puts C
