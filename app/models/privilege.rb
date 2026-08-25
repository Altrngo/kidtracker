# app/models/privilege.rb
class Privilege < ApplicationRecord
  belongs_to :user
  has_many :point_transactions

  validates :name,       presence: true
  validates :point_cost, presence: true,
                         numericality: { only_integer: true, greater_than: 0 }
  validates :active,     inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.active = true if active.nil?
  end
end
