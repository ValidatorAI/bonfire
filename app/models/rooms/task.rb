class Rooms::Task < Room
  belongs_to :project, optional: false

  validates :name, presence: true

  scope :for_project, ->(project) { where(project: project) }

  def default_involvement
    "mentions"
  end

  def complete!
    archive!
    SystemMessage.post(room: self, type: :task_completed, data: { name: name })
  end

  def reopen!
    unarchive!
    SystemMessage.post(room: self, type: :task_reopened, data: { name: name })
  end
end
