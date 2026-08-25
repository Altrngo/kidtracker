class Child < ApplicationRecord
  belongs_to :user

  has_many :child_items, dependent: :destroy
  has_many :items, through: :child_items
  has_many :weeks,  dependent: :destroy
  has_many :point_transactions, dependent: :destroy

  validates :first_name, presence: true
  validates :total_points, numericality: { only_integer: true }
  validates :avatar_color, presence: true

  AVATAR_COLORS = %w[#7C3AED #2563EB #059669 #D97706 #DC2626 #DB2777 #0891B2].freeze

  before_validation :set_default_avatar_color, on: :create
  before_validation :set_default_total_points, on: :create

  # Recalcule le solde depuis les transactions (utile pour audit/correction)
  def recalculate_points!
    update!(total_points: point_transactions.sum(:amount))
  end

  private

  def set_default_avatar_color
    self.avatar_color ||= AVATAR_COLORS.sample
  end

  def set_default_total_points
    self.total_points ||= 0
  end
end
