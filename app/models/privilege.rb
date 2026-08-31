# app/models/privilege.rb
class Privilege < ApplicationRecord
  belongs_to :user
  # nullify et non destroy : on ne supprime jamais l'historique des
  # points d'un enfant parce qu'un privilège a été retiré du catalogue.
  has_many :point_transactions, dependent: :nullify

  validates :name,       presence: true
  validates :point_cost, presence: true,
                         numericality: { only_integer: true, greater_than: 0 }
  validates :active,     inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }

  before_validation :set_defaults, on: :create

  # Combien d'unités un solde donné permet d'acheter
  def affordable_quantity(balance)
    return 0 if point_cost.to_i <= 0
    [balance / point_cost, 0].max
  end

  private

  def set_defaults
    self.active = true if active.nil?
  end
end
