class SessionsController < ApplicationController
  # Sessions are no longer needed - all web UI access is the Human Overseer
  # These routes redirect to root for backwards compatibility

  def new
    redirect_to root_url
  end

  def create
    redirect_to root_url
  end

  def destroy
    redirect_to root_url
  end
end
