Rails.application.config.after_initialize do
  storage_root = Rails.root.join("storage")
  File.delete(storage_root) if File.file?(storage_root)

  %w[ db files ].each do |dir|
    storage_root.join(dir).mkpath
  end
end
