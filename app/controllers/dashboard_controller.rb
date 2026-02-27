class DashboardController < ApplicationController
  def index
    @fields = Current.user.fields.includes(:field_visits).limit(5)
    @recent_visits = Current.user.field_visits.recent.includes(:field, :audio_messages).limit(10)
  end
end
