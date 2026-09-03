module Api
  class AttentionItemsController < Api::BaseController
    ATTENTION_ITEM_FIELDS = %i[
      id category title meta_text due_at overdue status
      project_id room_id user_id source_id source_type target_id target_type
      action_label ai_confirm created_at updated_at resolved_at resolved_by_id
    ].freeze

    def show
      attention_item = AttentionItem.find_by(id: params[:id])
      return render json: { error: "Attention item not found" }, status: :not_found unless attention_item

      render json: attention_item.as_json(only: ATTENTION_ITEM_FIELDS)
    end
  end
end
