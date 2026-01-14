# Morrowind Lore-Accurate Character Generator

![demo](./morrowgen-demo.gif)

Ruby application that generates **sound** and **lore-accurate** character sheets for *The Elder Scrolls III: Morrowind*.

## Features

### **Lore-Accurate Naming Engine:**
* Generates race-specific names (e.g., "Ash-Hanta" for Ashlanders, "Moghakh" for Orcs).
* **Argonians:** Generates dynamic Cyrodilic phrases (e.g., *"Hides-His-Eyes"*, *"Walks-In-Shadows"*) or traditional Jel names.
* **Orcs:** Correctly handles gendered surnames (`gro-` for males, `gra-` for females).
* **Imperials:** Context-aware gender suffixes for Roman-style names.

### **True Stat Calculation:**
* Calculates **Attributes** by summing: `Race Base Stats` + `Gender Differences` + `Birthsign Bonuses` + `Class Favored Attributes`.

### **Advanced Class Generator:**
* **Standard Mode:** Select from the classic, pre-made Morrowind classes.
* **Smart Mode:** Procedurally generates cohesive, playable classes using **"Architected Randomness"**.
  * Enforces logic rules (e.g., no conflicting armor types, mandatory offense/defense slots).
  * Auto-calculates Favored Attributes based on your skill spread.
  * Auto-names your class based on its archetype (e.g., "Battlemage", "Nightblade").
* **Chaos Mode:** Pure random generation for wild, unpredictable builds.

### **Complete Skill Generation:**
* Assigns **Major** (Base 30), **Minor** (Base 15), and **Misc** (Base 5) skills.
* Applies **+5 Specialization Bonus** (Combat/Magic/Stealth) to all relevant skills.
* Applies **Racial Bonuses** (e.g., Dunmer get +10 Destruction).
* Outputs the final, calculated value for every skill.

## Installation

1. Clone the repository.
2. Install the required gems (including the new CLI tools):

```bash
bundle install
```

## Usage

You can now run the generator from the project root in two ways:

### 1. Interactive Mode

Navigate through menus to select your gender, race, and class generation method.

```bash
ruby bin/cliMorrowGen.rb
```

### 2. Command Line Interface

Generate a character instantly by passing arguments. Defaults to "Standard" class generation.

```bash
ruby bin/MorrowGen.rb <gender> <race>
```

*Example:* `ruby bin/MorrowGen.rb male orc`

## Output Example

```text
IDENTITY
      Name:      Gurak gro-Agadbu
      Race:      Male Orc
      Birthsign: The Mage
      Class :    Archer
------------------------------------------------------------------------------------
ATTRIBUTES
      STR: 55                        INT: 30
      WIL: 50                        AGI: 45
      SPD: 30                        END: 50
      PER: 30                        LUC: 40
------------------------------------------------------------------------------------
SKILLS

Major:                        Minor:
      35 Long blade                  30 Medium armor
      45 Block                       20 Spear
      35 Athletics                   15 Restoration
      30 Light armor                 15 Unarmored
      30 Marksman                    15 Sneak

Other:
      20 Heavy armor                  5 Destruction
      20 Armorer                      5 Mysticism
      15 Axe                          5 Acrobatics
      10 Blunt weapon                 5 Hand to hand
       5 Illusion                     5 Short blade
       5 Alchemy                      5 Mercantile
       5 Conjuration                  5 Speechcraft
       5 Enchant                      5 Security
       5 Alteration                   5 Luck

```

## Roadmap

* [x] **Interactive CLI:** A robust menu system for easier selection.
* [x] **Custom Class Generator:** Random, yet **sound** class gen using "Architected Randomness" to avoid contradictory choices.
* [ ] **AI Backstories:** Integration with LLMs to generate a biography explaining *why* your Orc Archer knows Restoration.