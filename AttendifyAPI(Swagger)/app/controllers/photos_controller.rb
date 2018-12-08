class PhotosController < ApplicationController
  swagger_controller :photos, "photos Management"

    swagger_api :index do
        summary "Fetches all photos"
        notes "This lists all the photos"
        param :query, :for_andrew_id, :string, :optional, "Gets the photos for the andrew ID"
    end

    swagger_api :show do
        summary "Shows one photo"
        param :path, :id, :integer, :required, "photo ID"
        notes "This lists details of one photo"
        response :not_found
    end

    swagger_api :create do
        summary "Creates a new photo"
        param :form, :andrew_id, :string, :required, "Andrew ID"
        param :form, :photo_url, :string, :optional, "Photo URL"
        response :not_acceptable
    end

    swagger_api :update do
        summary "Updates an existing photo"
        param :path, :id, :integer, :required, "photo Id"
        param :form, :andrew_id, :string, :required, "Andrew ID"
        param :form, :photo_url, :string, :optional, "Photo URL"
        response :not_found
        response :not_acceptable
    end

    before_action :set_photo, only: [:show, :update, :destroy]

    # GET /photos
    def index
        @photos = Photo.all
        if params[:for_andrew_id].present?
          andrew_id = params[:for_andrew_id]
          @photos = Photo.for_andrew_id(andrew_id)
        end
        render json: @photos
    end

    # GET /photos/1
    def show
        render json: @photo
    end

    # POST /photos
    def create
        @photo = Photo.new(photo_params)

        if @photo.save
          render json: @photo, status: :created, location: @photo
        else
          render json: @photo.errors, status: :unprocessable_entity
        end
    end

    # PATCH/PUT /photos/1
    def update
        if @photo.update(photo_params)
            render json: @photo
        else
            render json: @photo.errors, status: :unprocessable_entity
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_photo
        @photo = Photo.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def photo_params
        params.permit(:andrew_id, :photo_url)
    end
end
