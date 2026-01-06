# Allow additional HTML tags in ActionText content
# This enables markdown-rendered tables to display properly

Rails.application.config.after_initialize do
  # Get current allowed tags and add table elements
  current_tags = ActionText::ContentHelper.allowed_tags || Rails::HTML5::SafeListSanitizer.allowed_tags
  ActionText::ContentHelper.allowed_tags = current_tags + %w[table thead tbody tfoot tr th td]
end
