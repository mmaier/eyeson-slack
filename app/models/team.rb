# Manages API keys
class Team
  include Mongoid::Document

  field :external_id, type: String
  field :api_key, type: String

  has_many :users, dependent: :destroy
  has_many :channels, dependent: :destroy

  validates :external_id, presence: true
  validates :external_id, uniqueness: true
  validates :api_key, presence: true

  index({ external_id: 1 }, unique: true)

  before_validation :obtain_api_key

  private

  def obtain_api_key
    # TODO: use slack configuration for key????
    self.api_key = 'c9558caed546e3d4f252'
  end
end
