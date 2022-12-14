class ActivitiesController < ApplicationController
  before_action :set_activity, only: [:show, :edit, :update, :destroy]

  def index
    @activities = Activity.all
    @user_booking = Booking.find_by(user: current_user, activity: @activity)

    if params[:query].present?
      sql_query = "name ILIKE :query OR location ILIKE :query"
      @activities = Activity.where(sql_query, query: "%#{params[:query]}%")
    end

    if params[:category].present?
      @activities = @activities.joins(:activity_categories).where(activity_categories: { category_id: params[:category]})
    end


    @markers = @activities.geocoded.map do |activity|
      {
        lat: activity.latitude,
        lng: activity.longitude,
        info_window: render_to_string(partial: "info_window", locals: { activity: activity }),
        image_url: helpers.asset_url("https://res.cloudinary.com/mariacend1910/image/upload/v1662372896/dog_pin_2_kgunoh.svg")
      }
    end
  end

  def new
    @activity = Activity.new
  end

  def create
    @activity = Activity.new(activity_params)
    @activity.user = current_user
    if @activity.save
      @categories = Category.where(id: params[:activity][:category_ids])
      @categories.each do |category|
        ActivityCategory.create(category: category, activity: @activity)
      end
      redirect_to activity_path(@activity)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user_booking = Booking.find_by(user: current_user, activity: @activity)
    @booking = Booking.new
    @comment = Comment.new
    @message = Message.new

    @chatroom = @activity.chatroom || Chatroom.create(name: @activity.name, activity: @activity)

    @markers =
    [{
      lat: @activity.latitude,
      lng: @activity.longitude,
      info_window: render_to_string(partial: "info_window", locals: { activity: @activity }),
      image_url: helpers.asset_url("https://res.cloudinary.com/mariacend1910/image/upload/v1662372896/dog_pin_2_kgunoh.svg")
    }]


  end

  def update
    if @activity.update(activity_params)
      redirect_to activity_path(@activity)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit

  end

  def destroy
    if @activity.user.id == current_user.id
      @activity.destroy
      redirect_to home_path, status: :see_other
    else
      redirect_to home_path, status: :see_other, notice: "You are not allowed to do this"
    end
  end

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:name, :description, :location, :start_date, :end_date, :start_time, :end_time, :dog_limit, :people_limit, :price, :status, :photo, activity_categories: { category_id: [] })
  end
end
