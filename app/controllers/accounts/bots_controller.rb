class Accounts::BotsController < ApplicationController
  before_action :ensure_can_administer
  before_action :set_bot, only: %i[ edit update destroy ]

  def index
    @bots = User.active_bots.ordered
  end

  def new
    @bot = User.active_bots.new
  end

  def create
    User.create_bot! bot_params
    redirect_to account_bots_url(return_to: return_to_param)
  end

  def edit
  end

  def update
    @bot.update_bot! bot_params
    redirect_to account_bots_url(return_to: return_to_param)
  end

  def destroy
    @bot.deactivate
    redirect_to account_bots_url(return_to: return_to_param)
  end

  private
    def return_to_param
      "company_settings" if params[:return_to] == "company_settings"
    end

    def set_bot
      @bot = User.active_bots.find(params[:id])
    end

    def bot_params
      params.require(:user).permit(:name, :avatar, :webhook_url)
    end
end
