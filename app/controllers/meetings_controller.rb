# Join a meeting
class MeetingsController < ApplicationController
  before_action :user_present

  def show
    # Add user to existing room and redirect to communication GUI
    user = {
      id: session[:user_id],
      name: session[:user_name]
    }

    # TODO: handle error
    room = Participant.new(params[:id], user)

    redirect_to room.url
  end

  private

  def user_present
    return if session[:user_id].present?
    redirect_to login_path(redirect_uri: meeting_path(id: params[:id]))
  end
end
