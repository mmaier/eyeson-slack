# Manages API keys
class Team
  include Mongoid::Document

  field :external_id, type: String
  field :url, type: String
  field :name, type: String

  has_many :users, dependent: :destroy
  has_many :channels, dependent: :destroy

  validates :external_id, presence: true
  validates :external_id, uniqueness: true
  validates :url, presence: true
  validates :name, presence: true

  index({ external_id: 1 }, unique: true)

  def self.setup!(external_id: nil, name: nil, url: nil)
    team = Team.find_or_initialize_by(external_id: external_id)
    return team unless team.new_record?
    team.url     = url
    team.name    = name
    team.save!
    team
  end

  def add!(access_token: nil, scope: nil, identity: {})
    user = User.find_or_initialize_by(team_id: id,
                                      external_id: identity['user']['id'])

    user.name         = identity['user']['name']
    user.email        = identity['user']['email']
    user.avatar       = identity['user']['image_48']
    user.access_token = access_token
    user.scope        = scope.split(',')
    user.save!
    user
  end
end
