module Users::SidebarHelper
  def each_membership_in_room_tree(memberships, &block)
    return enum_for(:each_membership_in_room_tree, memberships) unless block

    memberships = Array(memberships)
    memberships_by_room_id = memberships.index_by(&:room_id)
    children_by_parent_id = memberships.select { |membership| membership.room.parent_id.present? }
                                      .group_by { |membership| membership.room.parent_id }

    roots = memberships.select do |membership|
      parent_id = membership.room.parent_id
      parent_id.blank? || !memberships_by_room_id.key?(parent_id)
    end

    walk_room_tree(roots, children_by_parent_id, depth: 0, visited_room_ids: {}, &block)
  end

  def sidebar_turbo_frame_tag(src: nil, &)
    turbo_frame_tag :user_sidebar, src: src, target: "_top", data: {
      turbo_permanent: true,
      controller: "rooms-list read-rooms turbo-frame",
      rooms_list_unread_class: "unread",
      action: "presence:present@window->rooms-list#read read-rooms:read->rooms-list#read turbo:frame-load->rooms-list#loaded refresh-room:visible@window->turbo-frame#reload".html_safe # otherwise -> is escaped
    }, &
  end

  private
    def walk_room_tree(memberships, children_by_parent_id, depth:, visited_room_ids:, &block)
      memberships.each do |membership|
        next if visited_room_ids.key?(membership.room_id)

        visited_room_ids[membership.room_id] = true

        block.call(membership, depth)

        children = children_by_parent_id.fetch(membership.room_id, []).sort_by { |child| child.room.name.to_s.downcase }
        walk_room_tree(children, children_by_parent_id, depth: depth + 1, visited_room_ids: visited_room_ids, &block)
      end
    end
end
