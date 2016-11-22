# Manages API keys
class Team
  include Mongoid::Document

  field :external_id, type: String
  field :api_key, type: String
  field :setup_url, type: String
  field :ready, type: Boolean, default: false

  has_many :users, dependent: :destroy
  has_many :channels, dependent: :destroy

  validates :external_id, presence: true
  validates :external_id, uniqueness: true
  validates :api_key, presence: true
  validates :setup_url, presence: true
  validates :ready, presence: true

  index({ external_id: 1 }, unique: true)

  def self.setup!(name: nil, identity: {}, webhooks_url: nil)
    team = Team.new
    api_key = ApiKey.new(name: name, webhooks_url: webhooks_url)
    team.api_key = api_key.key
    team.setup_url = api_key.url
    team.external_id = identity['team']['id']
    team.save!

    team.add!(identity['user'])

    api_key.url
  end

  def add!(identity)
    user = User.find_or_initialize_by(
      team_id: id,
      external_id: identity['id']
    )
    user.name = identity['name']
    user.avatar = identity['image_48']
    user.save!
    user
  end

  private

  def obtain_api_key
    # TODO: use slack configuration for key????
    self.api_key = 'c9558caed546e3d4f252'
  end
end
