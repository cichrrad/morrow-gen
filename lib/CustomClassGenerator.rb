# lib/CustomClassGenerator.rb

class CustomClassGenerator
  SKILL_DATA = {
    'acrobatics' => { attr: 'str', type: :mobility },
    'alchemy' => { attr: 'int', type: :magic },
    'alteration' => { attr: 'wil', type: :magic },
    'armorer' => { attr: 'str', type: :utility },
    'athletics' => { attr: 'spd', type: :mobility },
    'axe' => { attr: 'str', type: :weapon }, # 1H
    'block' => { attr: 'agi', type: :defensive },
    'blunt_weapon' => { attr: 'str', type: :weapon }, # 1H
    'conjuration' => { attr: 'int', type: :magic },
    'destruction' => { attr: 'wil', type: :magic }, # Magic Offense
    'enchant' => { attr: 'int', type: :magic },
    'hand_to_hand' => { attr: 'spd', type: :weapon }, # 1H
    'heavy_armor' => { attr: 'end', type: :armor },
    'illusion' => { attr: 'per', type: :magic },
    'light_armor' => { attr: 'agi', type: :armor },
    'long_blade' => { attr: 'str', type: :weapon }, # 1H
    'marksman' => { attr: 'agi', type: :weapon, hands: 2 }, # 2H
    'medium_armor' => { attr: 'end', type: :armor },
    'mercantile' => { attr: 'per', type: :social },
    'mysticism' => { attr: 'wil', type: :magic },
    'restoration' => { attr: 'wil', type: :magic },
    'security' => { attr: 'int', type: :stealth },
    'short_blade' => { attr: 'spd', type: :weapon }, # 1H
    'sneak' => { attr: 'agi', type: :stealth },
    'spear' => { attr: 'end', type: :weapon, hands: 2 }, # 2H
    'speechcraft' => { attr: 'per', type: :social },
    'unarmored' => { attr: 'spd', type: :armor }
  }.freeze

  ARCHETYPES = {
    'Warrior' => {
      spec: 'combat',
      pri: %w[heavy_armor medium_armor spear axe long_blade blunt_weapon block armorer athletics]
    },
    'Mage' => {
      spec: 'magic',
      pri: %w[destruction alteration mysticism restoration illusion conjuration enchant alchemy unarmored]
    },
    'Thief' => {
      spec: 'stealth',
      pri: %w[security sneak light_armor short_blade marksman acrobatics mercantile speechcraft hand_to_hand]
    }
  }.freeze

  def initialize
    @all_skills = SKILL_DATA.keys
  end

  def generate_smart(custom_name = nil)
    archetype_key = ARCHETYPES.keys.sample
    archetype = ARCHETYPES[archetype_key]

    pool = @all_skills.dup
    majors = []

    # SLOT 1: PRIMARY OFFENSE
    offense_candidates = archetype[:pri].select { |s| is_offensive?(s) }
    offense_candidates = @all_skills.select { |s| is_offensive?(s) } if offense_candidates.empty?

    s1 = offense_candidates.sample
    if s1 && valid_candidate?(majors, s1)
      majors << s1
      pool.delete(s1)
    end

    # SLOT 2: PRIMARY ARMOR
    armor_candidates = archetype[:pri].select { |s| SKILL_DATA[s][:type] == :armor }
    armor_candidates = @all_skills.select { |s| SKILL_DATA[s][:type] == :armor } if armor_candidates.empty?

    s2 = armor_candidates.sample
    if s2 && valid_candidate?(majors, s2)
      majors << s2
      pool.delete(s2)
    end

    # SLOTS 3-5: WEIGHTED RANDOM
    while majors.size < 5
      candidate = if rand < 0.7
                    (pool & archetype[:pri]).sample || pool.sample
                  else
                    pool.sample
                  end

      if candidate && valid_candidate?(majors, candidate)
        majors << candidate
        pool.delete(candidate)
      end
    end

    # MINOR SKILLS
    minors = []
    while minors.size < 5
      candidate = pool.sample
      if candidate && valid_candidate?(majors + minors, candidate)
        minors << candidate
        pool.delete(candidate)
      end
    end

    favored_attrs = calculate_favored_attributes(majors + minors)

    build_class_hash(
      name: custom_name || generate_name(archetype_key, majors),
      spec: archetype[:spec],
      favored: favored_attrs,
      major: majors,
      minor: minors,
      desc: "A custom class generated with the #{archetype_key} archetype."
    )
  end

  def generate_chaos(custom_name = nil)
    pool = @all_skills.dup.shuffle
    majors = []

    while majors.size < 5 && !pool.empty?
      cand = pool.pop
      majors << cand if valid_candidate?(majors, cand)
    end

    minors = []
    while minors.size < 5 && !pool.empty?
      cand = pool.pop
      minors << cand if valid_candidate?(majors + minors, cand)
    end

    spec = %w[combat magic stealth].sample
    attrs = %w[str int wil agi spd end per].sample(2)

    build_class_hash(
      name: custom_name || 'Eccentric',
      spec: spec,
      favored: attrs,
      major: majors,
      minor: minors,
      desc: 'A completely random assortment of skills.'
    )
  end

  def format_preview(class_hash)
    <<~PREVIEW
      [ #{class_hash['name']} ] (#{class_hash['specialization'].capitalize})

      Attributes: #{class_hash['favored_attributes'].map(&:upcase).join(', ')}

      Major Skills:
      #{class_hash['major_skills'].map { |s| "- #{s.capitalize.gsub('_', ' ')}" }.join("\n")}

      Minor Skills:
      #{class_hash['minor_skills'].map { |s| "- #{s.capitalize.gsub('_', ' ')}" }.join("\n")}
    PREVIEW
  end

  private

  def is_offensive?(skill)
    data = SKILL_DATA[skill]
    return true if data[:type] == :weapon
    return true if skill == 'destruction'

    false
  end

  def valid_candidate?(current_skills, candidate)
    return false if current_skills.include?(candidate)

    cand_data = SKILL_DATA[candidate]

    # DETERMINE PHASE
    # < 5 means we are currently filling Majors
    # >= 5 means we are filling Minors
    is_major_phase = current_skills.size < 5

    existing_armors = current_skills.select { |s| SKILL_DATA[s][:type] == :armor }
    existing_offense = current_skills.select { |s| is_offensive?(s) }

    # Rule 1: Armor Limits
    if cand_data[:type] == :armor
      # Strict global exclusivity for Unarmored
      return false if existing_armors.include?('unarmored')
      return false if candidate == 'unarmored' && existing_armors.any?

      # Phase-based Quantity Limit
      if is_major_phase
        # MAJORS: Only 1 Armor allowed.
        return false if existing_armors.size >= 1
      elsif existing_armors.size >= 2
        # MINORS: Max 2 Armors total (Main + Backup).
        return false
      end
    end

    # Rule 2: Offensive Limits
    if is_offensive?(candidate)
      if is_major_phase
        # MAJORS: Only 1 Offensive skill allowed.
        return false if existing_offense.size >= 1
      elsif existing_offense.size >= 2
        # MINORS: Max 2 Offensive skills total.
        return false
      end
    end

    # Rule 3: The Block Logic
    if candidate == 'block'
      has_2h = current_skills.any? { |s| SKILL_DATA[s][:hands] == 2 }
      return false if has_2h

      # Must have at least one melee weapon to use block
      has_melee = current_skills.any? { |s| SKILL_DATA[s][:type] == :weapon && s != 'marksman' }
      return false unless has_melee
    end

    # Rule 4: The 2-Handed Logic
    return false if (cand_data[:hands] == 2) && current_skills.include?('block')

    # Rule 5: Clanking Ninja (Heavy Armor vs Sneak)
    return false if (candidate == 'sneak') && current_skills.include?('heavy_armor')
    return false if (candidate == 'heavy_armor') && current_skills.include?('sneak')

    # Rule 6: Armorer Utility
    if candidate == 'armorer'
      has_repairable = current_skills.any? do |s|
        d = SKILL_DATA[s]
        (d[:type] == :armor && s != 'unarmored') || (d[:type] == :weapon && s != 'hand_to_hand')
      end
      return false unless has_repairable
    end

    true
  end

  def calculate_favored_attributes(all_skills)
    counts = Hash.new(0)
    all_skills.each do |skill|
      attr = SKILL_DATA[skill][:attr]
      counts[attr] += 1
    end
    counts.sort_by { |_k, v| -v }.take(2).map(&:first)
  end

  def generate_name(archetype, majors)
    has_magic = majors.any? { |s| SKILL_DATA[s][:type] == :magic }
    has_stealth = majors.any? { |s| SKILL_DATA[s][:type] == :stealth }

    case archetype
    when 'Warrior' then has_magic ? 'Battlemage' : 'Adventurer'
    when 'Mage'    then has_stealth ? 'Nightblade' : 'Sorcerer'
    when 'Thief'   then has_magic ? 'Spellsword' : 'Agent'
    else 'Custom Class'
    end
  end

  def build_class_hash(name:, spec:, favored:, major:, minor:, desc:)
    {
      'name' => name,
      'description' => desc,
      'specialization' => spec,
      'favored_attributes' => favored,
      'major_skills' => major,
      'minor_skills' => minor
    }
  end
end
