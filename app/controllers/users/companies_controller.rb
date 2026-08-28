class Users::CompaniesController < ApplicationController
  before_action :set_company_context

  def home
  end

  def status
  end

  def settings
  end

  private
    def set_company_context
      @account = Current.account
      @users = User.active.ordered.limit(50)
      @bots = User.active_bots.ordered.limit(12)
      @projects = Current.user.projects.sort_by { |project| project.display_name.to_s.downcase }.first(6)
      @rooms_count = Current.user.rooms.without_directs.active.count
      @messages_this_week = Current.user.reachable_messages.where(created_at: 1.week.ago..Time.current).count
    end
end
