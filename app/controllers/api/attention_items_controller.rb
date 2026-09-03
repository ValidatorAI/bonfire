module Api
  class AttentionItemsController < Api::BaseController
    ATTENTION_ITEM_FIELDS = %i[
      id category title meta_text due_at overdue status
      project_id room_id user_id source_id source_type target_id target_type
      action_label ai_confirm created_at updated_at resolved_at resolved_by_id
    ].freeze
    DEFAULT_PER_PAGE = 40
    MAX_PER_PAGE = 200

    def index
      attention_items = AttentionItem.ordered
      count = attention_items.count

      if params[:page].present?
        per_page = params[:per_page].presence&.to_i&.clamp(1, MAX_PER_PAGE) || DEFAULT_PER_PAGE
        page = [ params[:page].to_i, 1 ].max
        attention_items = attention_items.offset((page - 1) * per_page).limit(per_page)

        render json: {
          count: count,
          page: page,
          per_page: per_page,
          attention_items: attention_items.map { |attention_item| serialize(attention_item) }
        }
      else
        render json: {
          count: count,
          attention_items: attention_items.map { |attention_item| serialize(attention_item) }
        }
      end
    end

    def create
      title = params[:title].presence
      category = params[:category].presence
      return render json: { error: "Title is required" }, status: :bad_request unless title
      return render json: { error: "Category is required" }, status: :bad_request unless category

      user = User.find_by(id: params[:user_id]) if params[:user_id].present?
      project = Project.find_by(id: params[:project_id]) if params[:project_id].present?
      room = Room.find_by(id: params[:room_id]) if params[:room_id].present?

      if params[:project_id].present? && project.nil?
        return render json: { error: "Project not found" }, status: :not_found
      end

      if params[:room_id].present? && room.nil?
        return render json: { error: "Room not found" }, status: :not_found
      end

      if params[:user_id].present? && user.nil?
        return render json: { error: "User not found" }, status: :not_found
      end

      attention_item = AttentionItem.new(
        title: title,
        category: category,
        meta_text: params[:meta_text],
        due_at: params[:due_at].present? ? Time.zone.parse(params[:due_at].to_s) : nil,
        status: params[:status].presence || "pending",
        overdue: params[:overdue].present? ? ActiveModel::Type::Boolean.new.cast(params[:overdue]) : false,
        user: user,
        project: project,
        room: room,
        source_id: params[:source_id],
        source_type: params[:source_type],
        target_id: params[:target_id],
        target_type: params[:target_type],
        action_label: params[:action_label],
        ai_confirm: params[:ai_confirm].present? ? ActiveModel::Type::Boolean.new.cast(params[:ai_confirm]) : false
      )

      unless attention_item.save
        return render json: { error: attention_item.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end

      render json: serialize(attention_item), status: :created
    rescue ArgumentError
      render json: { error: "Invalid date format for due_at" }, status: :unprocessable_entity
    end

    def show
      attention_item = AttentionItem.find_by(id: params[:id])
      return render json: { error: "Attention item not found" }, status: :not_found unless attention_item

      render json: serialize(attention_item)
    end

    private

    def serialize(attention_item)
      attention_item.as_json(only: ATTENTION_ITEM_FIELDS)
    end
  end
end
