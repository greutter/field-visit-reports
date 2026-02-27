class FieldVisitsController < ApplicationController
  before_action :set_field
  before_action :set_field_visit, only: %i[show destroy generate_report]

  def index
    @field_visits = @field.field_visits.recent.includes(:audio_messages)
  end

  def show
    @audio_messages = @field_visit.audio_messages.chronological
  end

  def new
    @field_visit = @field.field_visits.build(user: Current.user)
  end

  def create
    @field_visit = @field.field_visits.build(user: Current.user)

    if @field_visit.save
      redirect_to field_field_visit_path(@field, @field_visit), notice: "Field visit created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @field_visit.destroy
    redirect_to field_path(@field), notice: "Field visit was successfully deleted.", status: :see_other
  end

  def generate_report
    if @field_visit.audio_messages.empty?
      redirect_to field_field_visit_path(@field, @field_visit), alert: "No audio messages to generate report from."
      return
    end

    GenerateReportJob.perform_later(@field_visit.id)
    redirect_to field_field_visit_path(@field, @field_visit), notice: "Report generation started. Please refresh in a moment."
  end

  private

  def set_field
    @field = Current.user.fields.find(params[:field_id])
  end

  def set_field_visit
    @field_visit = @field.field_visits.find(params[:id])
  end
end
