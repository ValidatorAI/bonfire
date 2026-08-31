require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "grant membership to user" do
    rooms(:watercooler).memberships.grant_to(users(:kevin))
    assert rooms(:watercooler).users.include?(users(:kevin))
  end

  test "revoke membership from user" do
    rooms(:watercooler).memberships.revoke_from(users(:david))
    assert_not rooms(:watercooler).users.include?(users(:david))
  end

  test "revise memberships" do
    rooms(:watercooler).memberships.revise(granted: users(:kevin), revoked: users(:david))
    assert rooms(:watercooler).users.include?(users(:kevin))
    assert_not rooms(:watercooler).users.include?(users(:david))
  end

  test "create for users by giving them immediate membership" do
    room = Rooms::Closed.create_for({ name: "Hello!", creator: users(:david) }, users: [ users(:kevin), users(:david) ])
    assert room.users.include?(users(:kevin))
    assert room.users.include?(users(:david))
  end

  test "type" do
    assert Rooms::Open.new.open?
    assert_not Rooms::Open.new.direct?
    assert Rooms::Direct.new.direct?
    assert Rooms::Closed.new.closed?
  end

  test "default involvement for new users" do
    room = Rooms::Closed.create_for({ name: "Hello!", creator: users(:david) }, users: [ users(:kevin), users(:david) ])
    assert room.memberships.all? { |m| m.involved_in_mentions? }
  end

  test "auto-joins all agents when a new room is created" do
    project = Project.create!(name: "Bonfire Auto Join", path: "/tmp/bonfire-room-auto-join")
    alpha = project.agents.create!(name: "Agent Alpha", program: "Codex", model: "gpt-5.3-codex")
    beta = project.agents.create!(name: "Agent Beta", program: "Claude Code", model: "claude-sonnet")

    room = Rooms::Closed.create_for({ name: "Ops", creator: users(:david) }, users: [ users(:david) ])

    assert room.agents.include?(alpha)
    assert room.agents.include?(beta)
  end

  test "does not auto-join agents for direct rooms" do
    project = Project.create!(name: "Bonfire Direct Auto Join", path: "/tmp/bonfire-direct-room-auto-join")
    project.agents.create!(name: "Agent Gamma", program: "Codex", model: "gpt-5.3-codex")

    room = Rooms::Direct.find_or_create_for(User.where(id: [ users(:david).id, users(:kevin).id ]))

    assert_equal 0, room.agents.count
  end
end
