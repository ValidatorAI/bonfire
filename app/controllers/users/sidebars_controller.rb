class Users::SidebarsController < ApplicationController
  DIRECT_PLACEHOLDERS = 20

  def show
    all_memberships     = Current.user.memberships.visible.with_ordered_room
    @direct_memberships = extract_direct_memberships(all_memberships)
    @other_memberships  = prioritize_company_memberships(all_memberships.without(@direct_memberships).to_a)

    @direct_placeholder_users = find_direct_placeholder_users
  end

  private
    def extract_direct_memberships(all_memberships)
      all_memberships.select { |m| m.room.direct? }.sort_by { |m| m.room.updated_at }.reverse
    end

    def prioritize_company_memberships(memberships)
      home_memberships = memberships.select { |membership| company_home_room?(membership.room.name) }
      status_memberships = memberships.select { |membership| company_status_room?(membership.room.name) }
      remaining_memberships = memberships - home_memberships - status_memberships

      home_memberships + status_memberships + remaining_memberships
    end

    def company_home_room?(name)
      normalized_name = normalize_room_name(name)
      normalized_name == "home" || normalized_name == "company home"
    end

    def company_status_room?(name)
      normalize_room_name(name) == "company status"
    end

    def normalize_room_name(name)
      name.to_s
        .downcase
        .gsub(/[^a-z0-9 ]/, "")
        .squeeze(" ")
        .strip
    end

    def find_direct_placeholder_users
      exclude_user_ids = user_ids_already_in_direct_rooms_with_current_user.including(Current.user.id)
      User.active.where.not(id: exclude_user_ids).order(:created_at).limit(DIRECT_PLACEHOLDERS - exclude_user_ids.count)
    end

    def user_ids_already_in_direct_rooms_with_current_user
      Membership.where(room_id: Current.user.rooms.directs.pluck(:id), participant_type: "User").pluck(:participant_id).uniq
    end
end
