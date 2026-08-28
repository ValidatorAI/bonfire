class Accounts::UsersController < ApplicationController
  before_action :ensure_can_administer, only: :create
  before_action :ensure_can_administer, :set_user, only: %i[ update destroy activate ]

  def index
    set_page_and_extract_portion_from User.active.ordered.without_bots, per_page: 500
  end

  def create
    user = User.new(create_user_params)
    user.display_name = user.name if user.display_name.blank?

    if user.save
      redirect_to edit_account_url, notice: "User added"
    else
      redirect_to edit_account_url, alert: user.errors.full_messages.to_sentence.presence || "Unable to add user"
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to edit_account_url, alert: "Email address is already in use"
  end

  def update
    @user.update(role_params)
    redirect_after_member_change
  end

  def destroy
    @user.deactivate
    redirect_after_member_change
  end

  def activate
    @user.update!(status: :active)
    redirect_after_member_change
  end

  private
    def set_user
      @user = User.where(status: [ :active, :deactivated ]).without_bots.find(params[:user_id] || params[:id])
    end

    def redirect_after_member_change
      if params[:return_to] == "company_settings"
        redirect_to user_company_settings_path(user_id: "me")
      else
        redirect_to edit_account_url
      end
    end

    def role_params
      { role: params.require(:user)[:role].presence_in(%w[ member administrator ]) || "member" }
    end

    def create_user_params
      params.require(:user).permit(:name, :email_address, :password)
    end
end
