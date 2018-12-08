class EnrollmentsController < ApplicationController
  swagger_controller :enrollment, "Enrollment Management"

    swagger_api :index do
        summary "Fetches all enrollments"
        notes "This lists all the enrollments"
    end

    swagger_api :show do
        summary "Shows one enrollment"
        param :path, :id, :integer, :required, "enrollment ID"
        notes "This lists details of one enrollment"
        response :not_found
    end

    swagger_api :create do
        summary "Creates a new enrollment"
        param :form, :course_id, :integer, :required, "Course ID"
        param :form, :andrew_id, :string, :required, "Andrew ID"
        param :form, :active, :boolean, :required, "Active"
        response :not_acceptable
    end

    swagger_api :update do
        summary "Updates an existing enrollment"
        param :form, :course_id, :integer, :required, "Course ID"
        param :form, :andrew_id, :string, :required, "Andrew ID"
        param :form, :active, :boolean, :required, "Active"
        response :not_found
        response :not_acceptable
    end


    before_action :set_enrollment, only: [:show, :update, :destroy]

    # GET /enrollments
    def index
        @enrollments = Enrollment.all

        render json: @enrollments
    end

    # GET /enrollments/1
    def show
        render json: @enrollment
    end

    # POST /enrollments
    def create
        @enrollment = Enrollment.new(enrollment_params)

        if @enrollment.save
          render json: @enrollment, status: :created, location: @enrollment
        else
          render json: @enrollment.errors, status: :unprocessable_entity
        end
    end

    # PATCH/PUT /enrollments/1
    def update
        if @enrollment.update(enrollment_params)
            render json: @enrollment
        else
            render json: @enrollment.errors, status: :unprocessable_entity
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_enrollment
        @enrollment = Enrollment.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def enrollment_params
        params.permit(:course_id, :andrew_id, :active)
    end
end
