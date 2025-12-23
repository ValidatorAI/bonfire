require "zlib"

module AgentsHelper
  AGENT_COLORS = %w[
    #8B5CF6 #6366F1 #4F46E5 #7C3AED #5B21B6 #4338CA #3730A3
    #6D28D9 #7C3AED #8B5CF6 #A78BFA #C4B5FD
  ]

  def agent_avatar_background_color(agent)
    AGENT_COLORS[Zlib.crc32(agent.to_param) % AGENT_COLORS.size]
  end

  def agent_avatar_tag(agent, **options)
    # Wrap in a link-like structure to match user avatars
    content_tag :span, class: "btn avatar avatar--agent", title: agent.title, **options do
      content_tag :span, agent.initials,
        class: "avatar__initials",
        style: "background: #{agent_avatar_background_color(agent)}"
    end
  end

  def agent_presence_indicator(agent)
    status_class = case agent.status
    when "online" then "presence--online"
    when "idle" then "presence--idle"
    else "presence--offline"
    end

    content_tag :span, "", class: "presence-indicator #{status_class}"
  end
end
