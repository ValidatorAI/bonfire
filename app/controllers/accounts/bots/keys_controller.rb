class Accounts::Bots::KeysController < ApplicationController
  before_action :ensure_can_administer

  def update
    User.active_bots.find(params[:bot_id]).reset_bot_key
    redirect_to account_bots_url(return_to: return_to_param)
  end

  private
    def return_to_param
      "company_settings" if params[:return_to] == "company_settings"
    end
end
