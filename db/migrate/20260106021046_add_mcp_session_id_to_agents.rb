class AddMcpSessionIdToAgents < ActiveRecord::Migration[8.2]
  def change
    add_column :agents, :mcp_session_id, :string
    add_index :agents, :mcp_session_id
  end
end
