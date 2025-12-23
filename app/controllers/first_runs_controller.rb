class FirstRunsController < ApplicationController
  # First run is now automatic - redirects to root which triggers setup
  # These routes exist for backwards compatibility

  def show
    redirect_to root_url
  end

  def create
    redirect_to root_url
  end
end
