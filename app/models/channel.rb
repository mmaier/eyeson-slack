# Represents a room in eyeson
class Channel
  include Mongoid::Document

  field :external_id, type: String
  field :name, type: String

  belongs_to :team

  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :team_id }
  validates :name, presence: true

  index({ team_id: 1, external_id: 1 }, unique: true)
end