class StudentsController < ApplicationController
  swagger_controller :students, "students Management"

    swagger_api :index do
        summary "Fetches all students"
        notes "This lists all the students"
        param :query, :active, :boolean, :optional, "Filter on whether or not the student is active"
        param :query, :alphabetical, :boolean, :optional, "Order students by alphabetical"
    end

    swagger_api :show do
        summary "Shows one student"
        param :path, :id, :integer, :required, "student ID"
        notes "This lists details of one student"
        response :not_found
    end

    swagger_api :create do
        summary "Creates a new student"
        param :form, :first_name, :string, :required, "First name"
        param :form, :last_name, :string, :required, "Last name"
        param :form, :andrew_id, :string, :required, "Andrew ID, should be unique"
        param :form, :active, :boolean, :required, "Active"
        response :not_acceptable
    end

    swagger_api :update do
        summary "Updates an existing student"
        param :path, :id, :integer, :required, "student Id"
        param :form, :first_name, :string, :optional, "First name"
        param :form, :last_name, :string, :optional, "Last name"
        param :form, :password, :string, :optional, "Password"
        response :not_found
        response :not_acceptable
    end

    before_action :set_student, only: [:show, :update, :destroy]

    # GET /students
    def index
        @students = Student.all
        render json: @students

        if(params[:active].present?)
          @students = params[:active] == "true" ? @students.active : @students.inactive
        end

        if params[:alphabetical].present? && params[:alphabetical] == "true"
          @students = @students.alphabetical
        end
    end

    # GET /students/1
    def show
        render json: @student
    end

    # POST /students
    def create
        @student = Student.new(student_params)

        if @student.save
          render json: @student, status: :created, location: @student
        else
          render json: @student.errors, status: :unprocessable_entity
        end
    end

    # PATCH/PUT /students/1
    def update
        if @student.update(student_params)
            render json: @student
        else
            render json: @student.errors, status: :unprocessable_entity
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_student
        @student = Student.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def student_params
        params.permit(:first_name, :last_name, :andrew_id, :active)
    end
end
