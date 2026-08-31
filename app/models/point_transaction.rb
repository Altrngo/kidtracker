# app/models/point_transaction.rb
class PointTransaction < ApplicationRecord
  belongs_to :child
  belongs_to :privilege, optional: true
  # optional car : transactions antérieures à la traçabilité,
  # et transactions dont l'auteur a été supprimé.
  belongs_to :user, optional: true

  validates :amount,   presence: true, numericality: { only_integer: true }
  validates :reason,   presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  before_validation :set_default_quantity, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def redemption?        = privilege_id.present? || reason.to_s.start_with?("Rachat :")
  def manual_adjustment? = privilege_id.nil? && !reason.to_s.start_with?("Semaine du")
  def week_bonus?        = privilege_id.nil? && reason.to_s.start_with?("Semaine du")

  # Libellé affiché dans l'historique.
  # `reason` contient déjà le nom du privilège et la quantité au moment
  # de l'achat : il reste correct même si le privilège a été supprimé
  # ou renommé depuis.
  def label
    reason
  end

  def sign
    amount >= 0 ? "+#{amount}" : amount.to_s
  end

  # Auteur de la transaction, ou mention explicite si inconnu
  def author_name
    user&.display_name || "—"
  end

  def icon
    return "🎁" if redemption?
    return "⭐" if week_bonus?
    amount.positive? ? "➕" : "✏️"
  end

  private

  def set_default_quantity
    self.quantity ||= 1
  end
end
