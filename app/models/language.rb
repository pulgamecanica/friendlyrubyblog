class Language < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :extension, presence: true
  validates :interactive, inclusion: { in: [true, false] }

  scope :interactive, -> { where(interactive: true) }
  scope :by_name, -> { order(:name) }

  def self.find_or_create_by_name(name)
    return nil if name.blank?

    # Try to find existing language (case insensitive)
    existing = find_by('LOWER(name) = ?', name.downcase)
    return existing if existing

    # Create new language (non-interactive by default)
    create(
      name: name.titleize,
      extension: name.downcase,
      interactive: false
    )
  rescue ActiveRecord::RecordInvalid
    # Return nil if creation fails (e.g., due to validation errors)
    nil
  end

  def supports_execution?
    interactive? && executable_command.present?
  end
end
