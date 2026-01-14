require_relative 'NameGenerator'
require_relative 'StatsGenerator'
require_relative 'ClassGenerator'
require_relative 'SkillsGenerator'

class Character
  attr_accessor :name, :race, :race_specials, :gender, :birthsign, :char_class, :attributes, :skills, :major_skills, :minor_skills,
                :other_skills
  attr_reader :cached_heredoc

  def initialize(race_name, gender, name_db, stats_db, char_class_hash)
    @cached_heredoc = nil
    @race = race_name
    @gender = gender.downcase
    # Generate Name
    @name = name_db.generate(@race, @gender)

    # Load Race Stats
    race_def = stats_db.get_race_def(@race)
    raise "Race data missing for #{@race}" unless race_def

    @race_specials = race_def['specials']

    # Apply Gender-Specific Attributes
    base_stats = race_def['stats'][@gender]
    @attributes = base_stats.dup

    # Pick a Birthsign
    @birthsign = stats_db.get_random_birthsign

    # Apply Birthsign Bonuses (if any) to Attributes
    if @birthsign['attribute_bonus']
      @birthsign['attribute_bonus'].each do |attr, value|
        @attributes[attr] += value if @attributes[attr]
      end
    end

    # class
    @char_class = char_class_hash

    # add favored_atrribute boost
    favs = @char_class['favored_attributes']
    favs.each do |a|
      @attributes[a] += 10
    end

    @racial_skills = race_def['skill_bonuses']

    # skills
    skills_data_path = File.join(__dir__, '../data/skills.yml')
    sg = SkillsGenerator.new(skills_data_path, @char_class, @racial_skills)

    @skills = sg.skills
    @major_skills = sg.major
    @minor_skills = sg.minor
    @other_skills = sg.other
  end

  def to_s
    return @cached_heredoc unless @cached_heredoc.nil?

    # Helper lambda to format a single skill entry (e.g., "35 Long_blade")
    fmt = ->(k, v) { "#{v.to_s.rjust(3)} #{k.capitalize.gsub('_', ' ')}" }

    # Create arrays of formatted strings for each category
    maj_list = @major_skills.map(&fmt)
    min_list = @minor_skills.map(&fmt)
    other_list = @other_skills.map(&fmt)

    # Split 'Other' skills into two arrays of 9 for the two columns
    oth_col1, oth_col2 = other_list.each_slice(9).to_a

    # Helper lambda to join two lists into side-by-side columns
    # ljust(30) ensures the first column always takes up 30 characters
    join_cols = lambda { |left, right|
      left.zip(right).map { |l, r| "     #{l.ljust(30)} #{r}" }.join("\n")
    }

    # Generate the actual multiline strings
    maj_min_block = join_cols.call(maj_list, min_list)
    other_block   = join_cols.call(oth_col1, oth_col2)

    @cached_heredoc = <<~HEREDOC
      IDENTITY
            Name:      #{@name}
            Race:      #{@gender.capitalize} #{@race.capitalize}
            Birthsign: #{@birthsign['name']}
            Class :    #{@char_class['name']}
      ------------------------------------------------------------------------------------
      ATTRIBUTES
            STR: #{@attributes['str'].to_s.ljust(25)} INT: #{@attributes['int']}
            WIL: #{@attributes['wil'].to_s.ljust(25)} AGI: #{@attributes['agi']}
            SPD: #{@attributes['spd'].to_s.ljust(25)} END: #{@attributes['end']}
            PER: #{@attributes['per'].to_s.ljust(25)} LUC: #{@attributes['luc']}
      ------------------------------------------------------------------------------------
      SKILLS

      Major:                        Minor:
      #{maj_min_block}

      Other:
      #{other_block}
    HEREDOC
  end
end
