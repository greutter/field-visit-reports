class FieldsController < ApplicationController
  before_action :set_field, only: %i[show edit update destroy]

  def index
    @fields = Current.user.fields.order(created_at: :desc)
  end

  def show
    @field_visits = @field.field_visits.recent.includes(:audio_messages)
  end

  def new
    @field = Current.user.fields.build
  end

  def edit
  end

  def create
    @field = Current.user.fields.build(field_params)

    if @field.save
      redirect_to @field, notice: "Field was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @field.update(field_params)
      redirect_to @field, notice: "Field was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @field.destroy
    redirect_to fields_path, notice: "Field was successfully deleted.", status: :see_other
  end

  private

  def set_field
    @field = Current.user.fields.find(params[:id])
  end

  def field_params
    params.require(:field).permit(:name)
  end
end
