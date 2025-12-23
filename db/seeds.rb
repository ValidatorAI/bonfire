# db/seeds.rb
# Run with: bin/rails db:seed

puts "Setting up MCP Agent Chat..."

# This creates:
# - Account (singleton)
# - Human Overseer user (administrator)
# - "All Talk" main room
# - "Meta Events" room for system events
overseer = FirstRun.setup!

if overseer
  puts "  Created Human Overseer: #{overseer.name}"
  puts "  Created account: #{Account.first.name}"
  puts "  Created rooms:"
  Room.all.each { |r| puts "    - #{r.name} (#{r.class.name.demodulize})" }
else
  puts "  Already set up (Account exists)"
end

puts "Done!"
