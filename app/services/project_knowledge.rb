# frozen_string_literal: true

class ProjectKnowledge
  ROOT_STORAGE_DIR = Rails.root.join("storage", "projects")

  class << self
    def root_path_for(project)
      # Check both storage/projects/:id and project.path if directory exists
      storage_dir = ROOT_STORAGE_DIR.join(project.id.to_s)
      return storage_dir if Dir.exist?(storage_dir)

      if project.path.present? && Dir.exist?(project.path)
        return Pathname.new(project.path)
      end

      storage_dir
    end

    def ensure_storage_dir(project)
      dir = ROOT_STORAGE_DIR.join(project.id.to_s)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end

    def safe_resolve_path(project, relative_path)
      base_dir = root_path_for(project).expand_path
      return nil unless Dir.exist?(base_dir)

      # Clean and sanitize relative path
      cleaned_rel = relative_path.to_s.strip.delete_prefix("/")
      return nil if cleaned_rel.blank?

      target_path = base_dir.join(cleaned_rel).expand_path

      # Security: Path traversal protection
      if target_path.to_s.start_with?(base_dir.to_s) && File.exist?(target_path)
        target_path
      else
        nil
      end
    end

    def directory_tree(project)
      base_dir = root_path_for(project)
      return [] unless Dir.exist?(base_dir)

      build_tree(base_dir, base_dir)
    end

    def render_markdown(text)
      renderer = Redcarpet::Render::HTML.new(
        filter_html: false,
        no_images: false,
        no_links: false,
        no_styles: false,
        safe_links_only: true,
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
        no_intra_emphasis: true,
        space_after_headers: true,
        strikethrough: true,
        superscript: false,
        tables: true,
        underline: true
      })

      markdown.render(text.to_s)
    end

    private

    def build_tree(current_dir, base_dir)
      entries = []

      # Sort directories first, then files
      items = Dir.children(current_dir).sort_by do |name|
        child_path = current_dir.join(name)
        [File.directory?(child_path) ? 0 : 1, name.downcase]
      end

      items.each do |name|
        next if name.start_with?(".")

        child_path = current_dir.join(name)
        rel_path = child_path.relative_path_from(base_dir).to_s

        if File.directory?(child_path)
          children = build_tree(child_path, base_dir)
          entries << {
            type: :directory,
            name: name,
            relative_path: rel_path,
            children: children
          }
        elsif File.file?(child_path)
          ext = File.extname(name).downcase
          entries << {
            type: :file,
            name: name,
            relative_path: rel_path,
            extension: ext,
            is_markdown: %w[.md .markdown].include?(ext),
            is_html: %w[.html .htm].include?(ext)
          }
        end
      end

      entries
    end
  end
end
