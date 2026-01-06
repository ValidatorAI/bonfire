class ContentFilters::MarkdownFilter < ActionText::Content::Filter
  # Markdown patterns that indicate intentional formatting
  MARKDOWN_PATTERNS = [
    /\*\*[^*]+\*\*/,              # **bold**
    /__[^_]+__/,                  # __bold__
    /(?<!\S)\*[^*\s][^*]*\*(?!\S)/, # *italic* with word boundaries
    /(?<!\S)_[^_\s][^_]*_(?!\S)/, # _italic_ with word boundaries
    /`[^`]+`/,                    # `inline code`
    /```[\s\S]*?```/m,            # ```code blocks```
    /^\s*\#{1,6}\s+/m,            # # headers
    /^\s*[-*+]\s+/m,              # - list items
    /^\s*\d+\.\s+/m,              # 1. numbered lists
    /\[[^\]]+\]\([^)]+\)/,        # [link](url)
    /^\s*>\s+/m,                  # > blockquotes
    /~~[^~]+~~/,                  # ~~strikethrough~~
  ].freeze

  def applicable?
    contains_markdown?(content.to_plain_text)
  end

  def apply
    plain_text = content.to_plain_text
    html = markdown_to_html(plain_text)

    fragment.update do |source|
      source.inner_html = html
    end
  end

  private

  def contains_markdown?(text)
    MARKDOWN_PATTERNS.any? { |pattern| text.match?(pattern) }
  end

  def markdown_to_html(text)
    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,        # SECURITY: escape raw HTML in input
      no_images: false,
      no_links: false,
      no_styles: true,          # SECURITY: no inline styles
      safe_links_only: true,    # SECURITY: block javascript: links
      with_toc_data: false,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" }
    )

    markdown = Redcarpet::Markdown.new(renderer, {
      autolink: true,
      disable_indented_code_blocks: false,
      fenced_code_blocks: true,
      footnotes: false,
      highlight: false,
      no_intra_emphasis: true,  # Don't treat underscores_in_words as emphasis
      space_after_headers: true,
      strikethrough: true,
      superscript: false,
      tables: true,
      underline: false          # Avoid conflict with _italic_
    })

    markdown.render(text)
  end
end
