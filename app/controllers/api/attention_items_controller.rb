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
