module Agent::Mentionable
  extend ActiveSupport::Concern

  include ActionText::Attachable

  def to_attachable_partial_path
    "agents/mention"
  end

  def to_trix_content_attachment_partial_path
    "agents/mention"
  end

  def attachable_plain_text_representation(caption)
    "@#{name}"
  end
end
