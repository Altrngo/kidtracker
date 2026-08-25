class Item < ApplicationRecord
  belongs_to :user

  has_many :child_items, dependent: :destroy
  has_many :children, through: :child_items

  CATEGORIES = %w[matin soir comportement hygiène école].freeze

  validates :name,     presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validates :active,   inclusion: { in: [ true, false ] }

  before_validation :set_defaults, on: :create

  scope :active, -> { where(active: true) }

  private

  def set_defaults
    self.active = true if active.nil?
  end
end
