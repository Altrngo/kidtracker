# app/models/point_transaction.rb
class PointTransaction < ApplicationRecord
  belongs_to :child
  belongs_to :privilege, optional: true

  validates :amount,  presence: true, numericality: { only_integer: true }
  validates :reason,  presence: true

  scope :recent, -> { order(created_at: :desc) }

  # Types de transaction pour l'affichage
  def week_bonus?
    privilege_id.nil? && amount.positive?
  end

  def manual_adjustment?
    privilege_id.nil?
  end

  def redemption?
    privilege_id.present?
  end

  def label
    if redemption?
      "Privilège : #{privilege.name}"
    else
      reason
    end
  end

  def sign
    amount >= 0 ? "+#{amount}" : amount.to_s
  end
end
