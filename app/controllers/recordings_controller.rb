# Redirect user to valid recording url
class RecordingsController < ApplicationController
  def show
    recording = Eyeson::Recording.find(params[:id])
    redirect_to recording.url
  end
end
