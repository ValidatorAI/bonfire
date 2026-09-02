module Api
  class MessagesController < Api::BaseController
    MESSAGE_FIELDS = %i[
      id room_id creator_id creator_type system system_type created_at updated_at
    ].freeze
    DEFAULT_PER_PAGE = 40
    MAX_PER_PAGE = 200

    def index
      project = find_project(params[:project_id])
      return render json: { error: "Project not found" }, status: :not_found unless project

      room = find_room(project, params[:room_id])
      return render json: { error: "Room not found" }, status: :not_found unless room

      messages = room.messages.ordered
      count = messages.count

      if params[:page].present?
        per_page = params[:per_page].presence&.to_i&.clamp(1, MAX_PER_PAGE) || DEFAULT_PER_PAGE
        page = [ params[:page].to_i, 1 ].max
        messages = messages.offset((page - 1) * per_page).limit(per_page)

        render json: { count: count, page: page, per_page: per_page, messages: messages.map { |message| serialize(message) } }
      else
        render json: { count: count, messages: messages.map { |message| serialize(message) } }
      end
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
