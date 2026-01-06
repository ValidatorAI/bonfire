module Mcp
  class ToolRegistry
    def self.all
      [
        # Identity
        Mcp::Identity::RegisterAgentTool,
        Mcp::Identity::UpdateAgentTaskTool,
        Mcp::Identity::UpdateAgentStatusTool,
        Mcp::Identity::GetAgentProfileTool,
        Mcp::Identity::ListAgentsTool,
        # Room
        Mcp::Room::ListRoomsTool,
        Mcp::Room::JoinRoomTool,
        Mcp::Room::LeaveRoomTool,
        Mcp::Room::CreateTaskRoomTool,
        Mcp::Room::GetRoomMembersTool,
        Mcp::Room::SetInvolvementTool,
        # Messaging
        Mcp::Messaging::SendMessageTool,
        Mcp::Messaging::FetchMessagesTool,
        Mcp::Messaging::GetUnreadRoomsTool,
        Mcp::Messaging::MarkRoomReadTool,
        Mcp::Messaging::PollMessagesTool,
        Mcp::Messaging::SearchMessagesTool,
        # File Reservations
        Mcp::FileReservations::ReserveFilesTool,
        Mcp::FileReservations::ReleaseReservationTool,
        Mcp::FileReservations::RenewReservationTool,
        Mcp::FileReservations::ListReservationsTool,
        Mcp::FileReservations::CheckConflictsTool,
        # Workflow
        Mcp::Workflow::MacroStartSessionTool,
        Mcp::Workflow::HeartbeatTool
      ]
    end
  end
end
