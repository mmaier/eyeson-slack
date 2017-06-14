# Represents a room in eyeson
class Channel
  include Mongoid::Document

  field :external_id, type: String
  field :access_key, type: String
  field :name, type: String
  field :new_command, type: Boolean, default: false
  field :thread_id, type: String
  field :webinar_mode, type: Boolean, default: false
  field :users_mentioned, type: Array

  belongs_to :team

  validates :external_id, presence: true
  validates :external_id, uniqueness: true
  validates :name, presence: true
  validates :new_command, presence: true
  validates :webinar_mode, presence: true

  index({ external_id: 1 }, unique: true)

  before_update do
    self.new_command = false if thread_id_changed? && thread_id
  end
end
