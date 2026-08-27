class Users::ProjectsController < ApplicationController
  before_action :set_company_context
  before_action :set_project

  def overview
  end

  def status
  end

  def all_hands
  end

  private
    def set_company_context
      @account = Current.account
      @users = User.active.ordered.limit(50)
      @projects = Current.user.projects.sort_by { |project| project.display_name.to_s.downcase }.first(6)
      @rooms_count = Current.user.rooms.without_directs.active.count
      @messages_this_week = Current.user.reachable_messages.where(created_at: 1.week.ago..Time.current).count
    end

    def set_project
      @project = Current.user.projects.find_by(id: params[:id])
      raise ActiveRecord::RecordNotFound if @project.blank?
    end
end