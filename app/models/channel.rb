# Represents a room in eyeson
class Channel
  include Mongoid::Document

  field :external_id, type: String
  field :access_key, type: String
  field :name, type: String
  field :thread_id, type: String
  field :webinar_mode, type: Boolean, default: false
  field :initializer_id, type: BSON::ObjectId
  field :last_question_at, type: DateTime

  belongs_to :team

  validates :external_id, presence: true
  validates :external_id, uniqueness: true
  validates :name, presence: true
  validates :webinar_mode, presence: true

  index({ external_id: 1 }, unique: true)
end
