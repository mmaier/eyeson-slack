# Store user information
class User
  include Mongoid::Document

  field :external_id, type: String
  field :access_token, type: String
  field :name, type: String
  field :avatar, type: String

  belongs_to :team

  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :team_id }
  validates :access_token, presence: true
  validates :name, presence: true

  index({ team_id: 1, external_id: 1 }, unique: true)
end
