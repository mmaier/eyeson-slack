# Manages API keys
class Team
  include Mongoid::Document

  field :external_id, type: String
  field :access_token, type: String
  field :api_key, type: String

  has_many :users, dependent: :destroy
  has_many :channels, dependent: :destroy

  validates :external_id, presence: true
  validates :external_id, uniqueness: true
  validates :access_token, presence: true
  validates :api_key, presence: true

  index({ external_id: 1 }, unique: true)

  def self.setup!(access_token: nil, identity: {})
    team = Team.find_or_initialize_by(external_id: identity['team_id'])
    if team.new_record?
      api_key = ApiKey.new
      team.api_key = api_key.key
      team.external_id = identity['team_id']
    end
    team.access_token = access_token
    team.save!
    team
  end

  def add!(access_token: nil, identity: {})
    user = User.find_or_initialize_by(team_id: id,
                                      external_id: identity['user_id'])

    profile = identity['profile']
    user.name = "#{profile['first_name']} #{profile['last_name']}"
    user.name = identity['user'] if user.name.blank?
    user.email = profile['email']
    user.avatar = profile['image_48']
    user.access_token = access_token
    user.save!
    user
  end
end
