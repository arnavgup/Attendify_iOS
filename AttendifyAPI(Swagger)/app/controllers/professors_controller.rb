class ProfessorsController < ApplicationController
  swagger_controller :professor, "Professor Management"

    swagger_api :index do
        summary "Fetches all professors"
        notes "This lists all the professors"
    end

    swagger_api :show do
        summary "Shows one professor"
        param :path, :id, :integer, :required, "professor ID"
        notes "This lists details of one professor"
        response :not_found
    end

    swagger_api :create do
        summary "Creates a new professor"
        param :form, :email, :string, :required, "E-mail, should be a cmu email"
        param :form, :first_name, :string, :required, "First Name"
        param :form, :last_name, :string, :required, "Last Name"
        param :form, :password, :string, :required, "password"
        response :not_acceptable
    end

    swagger_api :update do
        summary "Updates an existing professor"
        param :form, :email, :string, :required, "E-mail, should be a cmu email"
        param :form, :first_name, :string, :required, "First Name"
        param :form, :last_name, :string, :required, "Last Name"
        param :form, :password, :string, :required, "password"
        response :not_found
        response :not_acceptable
    end


    before_action :set_professor, only: [:show, :update, :destroy]

    # GET /professors
    def index
        @professors = Professor.all

        render json: @professors
    end

    # GET /professors/1
    def show
        render json: @professor
    end

    # POST /professors
    def create
        @professor = Professor.new(professor_params)

        if @professor.save
          render json: @professor, status: :created, location: @professor
        else
          render json: @professor.errors, status: :unprocessable_entity
        end
    end

    # PATCH/PUT /professors/1
    def update
        if @professor.update(professor_params)
            render json: @professor
        else
            render json: @professor.errors, status: :unprocessable_entity
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_professor
        @professor = Professor.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def professor_params
        params.permit(:first_name, :last_name, :email, :password)
    end
end
