require "test_helper"

class Rooms::ClosedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show redirects to get general show" do
    get rooms_open_url(users(:david).rooms.closeds.last)
    assert_redirected_to room_url(users(:david).rooms.closeds.last)
  end

  test "new" do
    get new_rooms_closed_url
    assert_response :success
  end

  test "new for project only lists project users and labels human vs ai" do
    project = Project.create!(
      name: "Bravo",
      slug: "bravo-#{SecureRandom.hex(4)}",
      path: "/tmp/bravo-#{SecureRandom.hex(8)}"
    )
    ProjectUser.create!(project: project, user: users(:david))
    ProjectUser.create!(project: project, user: users(:bender))
    ProjectUser.create!(project: project, user: users(:kevin))

    get new_rooms_closed_url(project_id: project.id)

    assert_response :success
    assert_select "li[data-value='david']", count: 1
    assert_select "li[data-value='kevin']", count: 1
    assert_select "li[data-value='bender bot']", count: 1
    assert_select "li[data-value='jason']", count: 0
    assert_select "li[data-value='david'] span", text: "(Human)", count: 1
    assert_select "li[data-value='bender bot'] span", text: "(AI)", count: 1
  end

  test "create" do
    assert_turbo_stream_broadcasts [ users(:david), :rooms ], count: 1 do
    assert_turbo_stream_broadcasts [ users(:kevin), :rooms ], count: 1 do
    assert_turbo_stream_broadcasts [ users(:jason), :rooms ], count: 1 do
      post rooms_closeds_url, params: { room: { name: "My New Room" }, user_ids: [ users(:david).id, users(:kevin).id, users(:jason).id ] }
    end
    end
    end

    new_room = Room.last
    assert_equal new_room.memberships.count, 3
    assert_redirected_to room_url(Room.last)
  end

  test "create for project ignores non-project grantee ids" do
    project = Project.create!(
      name: "Charlie",
      slug: "charlie-#{SecureRandom.hex(4)}",
      path: "/tmp/charlie-#{SecureRandom.hex(8)}"
    )
    ProjectUser.create!(project: project, user: users(:david))
    ProjectUser.create!(project: project, user: users(:kevin))

    post rooms_closeds_url, params: {
      room: { name: "Project room", project_id: project.id },
      user_ids: [ users(:david).id, users(:kevin).id, users(:jason).id ]
    }

    room = Room.last
    assert_redirected_to room_url(room)
    assert_includes room.users, users(:david)
    assert_includes room.users, users(:kevin)
    assert_not_includes room.users, users(:jason)
  end

  test "create from project settings redirects back to project settings" do
    project = Project.create!(
      name: "Foxtrot",
      slug: "foxtrot-#{SecureRandom.hex(4)}",
      path: "/tmp/foxtrot-#{SecureRandom.hex(8)}"
    )
    ProjectUser.create!(project: project, user: users(:david))

    post rooms_closeds_url, params: {
      from_project_settings: "1",
      room: {
        name: "Private Settings Room",
        project_id: project.id
      },
      user_ids: [ users(:david).id ]
    }

    assert_redirected_to edit_rooms_project_url(project.id, by: "project")
  end

  test "create forbidden by non-admin when account restricts creation to admins" do
    accounts(:signal).settings.restrict_room_creation_to_administrators = true
    accounts(:signal).save!

    sign_in :jz
    post rooms_closeds_url, params: { room: { name: "My New Room" }, user_ids: [ users(:david).id, users(:kevin).id, users(:jason).id ] }
    assert_response :forbidden
  end


  test "update with membership revisions" do
    assert_difference -> { rooms(:designers).reload.users.count }, -1 do
      put rooms_closed_url(rooms(:designers)), params: {
        room: { name: "New Name" }, user_ids: rooms(:designers).users.without(users(:jason)).collect(&:id)
      }
    end

    assert_redirected_to room_url(rooms(:designers))
    assert rooms(:designers).reload.name, "New Name"
  end

  test "update an open room to be closed" do
    put rooms_closed_url(rooms(:pets)), params: { room: { name: "Doesn't matter" }, user_ids: [ users(:david).id, users(:jason).id ] }
    assert_equal rooms(:pets).memberships.count, 2
  end

  test "only admins or creators can update" do
    sign_in :jz

    assert_turbo_stream_broadcasts :rooms, count: 0 do
      put rooms_closed_url(rooms(:designers)), params: { room: { name: "New Name" } }
    end

    assert_response :forbidden
    assert rooms(:designers).reload.name, "Designers"
  end

  test "remove yourself" do
    assert_difference -> { users(:david).rooms.count }, -1 do
      put rooms_closed_url(rooms(:designers), params: { room: { name: "Designers" }, user_ids: [ users(:jason).id, users(:jz).id ] })

      assert_redirected_to room_url(rooms(:designers))
      follow_redirect!
      assert_redirected_to root_url
    end
  end
end
