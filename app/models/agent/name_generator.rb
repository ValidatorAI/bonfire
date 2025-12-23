class Agent::NameGenerator
  # Format: "<Name> the <Title>" (e.g., "Gary the Magnificent", "Tim the Enchanter")

  NAMES = %w[
    Keith Gary Dave Colin Trevor Nigel Brian Derek Kevin Barry
    Gerald Clive Neville Reg Stan Norman Malcolm Graham Terry
    Eric Tim Dennis Roger Herbert Ian Neil Paul John Mike
    Steve Pete Phil Chris Mark Tony Wayne Craig Glen Ross
    Angus Bruce Basil Rupert Percy Monty Bertie Simon Gavin
    Chuck Brad Todd Kyle Chad Brett Chet Brock Trent Lance
    Dean Earl Duke Hank Buck Bud Chip Skip Rusty Billy Bobby
    Jimmy Tommy Danny Randy Cody Jed Clint Wade Clay Roy Troy
    Jay Ray Vince Carl Walt Gus Lou Frank Daryl Dwight Merle
    Tom Bob Dan Ben Sam Max Jack Jim Joe Ed Ted Fred Ned
  ].freeze

  TITLES = %w[
    Adequate Enchanter Shrubber Brave Wise Pedantic Verbose Punctual
    Humble Meek Gentle Mild Cautious Hesitant Reluctant Patient Peaceful
    Pious Just Good Fair Elder Bald Short Silent Simple Mad Young Old Great
    Unready Confessor Conqueror Lionheart Terrible Magnificent Bold Boneless
    Fairhair Hammer Ironside Lackland Inexorable Relentless Unstoppable
    Inevitable Indefatigable Unyielding Undeterred Unflappable
    Wanderer Seeker Watcher Keeper Herald Scribe Oracle Sage Builder Mender
    Bear Wolf Fox Hawk Badger Serpent Raven Hound
    Compiler Interpreter Deployer Handler Dispatcher Resolver Executor
    Constructor Destructor Translator Marshaller Orchestrator Allocator
    Collector Observer Listener Publisher Mapper Profiler Balancer Sanitizer
  ].freeze

  def self.generate(project, attempts: 50)
    attempts.times do
      name = "#{NAMES.sample} the #{TITLES.sample}"
      return name unless project.agents.exists?(name: name)
    end
    # Fallback with random suffix if all attempts fail
    "#{NAMES.sample} the #{TITLES.sample} #{SecureRandom.alphanumeric(4)}"
  end
end
