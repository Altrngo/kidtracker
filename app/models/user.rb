# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable

  has_many :children,           dependent: :destroy
  has_many :items,              dependent: :destroy
  has_many :privileges,         dependent: :destroy
  # Les transactions ne sont pas détruites avec l'utilisateur :
  # l'historique des points de l'enfant doit survivre à la suppression
  # d'un compte parent. L'auteur devient simplement inconnu.
  has_many :point_transactions, dependent: :nullify

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { in: 2..30 },
            format: {
              with: /\A[a-zA-Z0-9_.\-]+\z/,
              message: "ne peut contenir que lettres, chiffres, tiret, point et underscore"
            }

  before_validation :normalize_username

  def admin?
    admin
  end

  # Nom affiché partout dans l'interface
  def display_name
    username.presence || email.split("@").first
  end

  private

  def normalize_username
    self.username = username.to_s.strip.presence
  end
end
