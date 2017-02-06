# Store user information
class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :external_id, type: String
  field :access_token, type: String
  field :scope, type: Array
  field :name, type: String
  field :email, type: String
  field :avatar, type: String

  belongs_to :team

  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :team_id }
  validates :access_token, presence: true
  validates :scope, presence: true
  validates :name, presence: true
  validates :email, presence: true

  index({ team_id: 1, external_id: 1 }, unique: true)

  def scope_required!(required)
    missing = []
    required.each do |s|
      missing << s unless scope.include?(s)
    end
    raise SlackApi::MissingScope, missing.join(',') if missing.any?
  end
end
