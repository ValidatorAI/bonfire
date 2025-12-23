class FileReservationCleanupJob < ApplicationJob
  queue_as :default

  def perform
    FileReservation.cleanup_expired!
  end
end
