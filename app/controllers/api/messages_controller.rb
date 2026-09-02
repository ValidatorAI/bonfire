module Api
  class MessagesController < Api::BaseController
    MESSAGE_FIELDS = %i[
      id room_id creator_id creator_type system system_type created_at updated_at
    ].freeze

    def index
      project = find_project(params[:project_id])
      return render json: { error: "Project not found" }, status: :not_found unless project

      room = find_room(project, params[:room_id])
      return render json: { error: "Room not found" }, status: :not_found unless room

      render json: room.messages.ordered.map { |message| serialize(message) }
    end

    def show
      project = find_project(params[:project_id])
      return render json: { error: "Project not found" }, status: :not_found unless project

      room = find_room(project, params[:room_id])
      return render json: { error: "Room not found" }, status: :not_found unless room

      message = room.messages.find_by(id: params[:id])
      return render json: { error: "Message not found" }, status: :not_found unless message

      render json: serialize(message)
    end

    private

    def serialize(message)
      message.as_json(only: MESSAGE_FIELDS).merge(body: message.plain_text_body)
    end
  end
end
