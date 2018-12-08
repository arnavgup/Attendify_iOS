class AttendancesController < ApplicationController
  swagger_controller :attendances, "attendances Management"

    swagger_api :index do
        summary "Fetches all attendances"
        notes "This lists all the attendances"
        param :query, :for_andrew_id, :string, :optional, "Gets the attendance for the andrew ID"
        param :query, :for_class, :integer, :optional, "Gets the attendance for the class ID"
    end

    swagger_api :show do
        summary "Shows one attendance"
        param :path, :id, :integer, :required, "attendance ID"
        notes "This lists details of one attendance"
        response :not_found
    end

    swagger_api :create do
        summary "Creates a new attendance"
        param :form, :andrew_id, :string, :required, "Andrew ID"
        param :form, :date, :timestamp, :required, "Date"
        param :form, :course_id, :integer, :required, "The ID of the class"
        param :form, :attendance_type, :string, :required, "The type can be Present, Absent, Excused"
        response :not_acceptable
    end

    swagger_api :update do
        summary "Updates an existing attendance"
        param :path, :id, :integer, :required, "attendance Id"
        param :form, :andrew_id, :string, :required, "Andrew ID"
        param :form, :date, :timestamp, :required, "Date"
        param :form, :course_id, :integer, :required, "The ID of the class"
        param :form, :attendance_type, :string, :required, "The type can be Present, Absent, Excused"
        response :not_found
        response :not_acceptable
    end

    before_action :set_attendance, only: [:show, :update, :destroy]

    # GET /attendances
    def index
        @attendances = Attendance.all
        if params[:for_andrew_id].present?
          andrew_id = params[:for_andrew_id]
          @attendances = Attendance.for_andrew_id(andrew_id)
        end

        if params[:for_course].present?
          course = params[:for_course]
          @attendances = Attendance.for_course(course)
        end
        render json: @attendances
    end

    # GET /attendances/1
    def show
        render json: @attendance
    end

    # POST /attendances
    def create
        @attendance = Attendance.new(attendance_params)

        if @attendance.save
          render json: @attendance, status: :created, location: @attendance
        else
          render json: @attendance.errors, status: :unprocessable_entity
        end
    end

    # PATCH/PUT /attendances/1
    def update
        if @attendance.update(attendance_params)
            render json: @attendance
        else
            render json: @attendance.errors, status: :unprocessable_entity
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_attendance
        @attendance = Attendance.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def attendance_params
        params.permit(:andrew_id, :course_id, :date, :attendance_type)
    end
end
