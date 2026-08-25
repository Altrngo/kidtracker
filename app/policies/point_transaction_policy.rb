# app/policies/point_transaction_policy.rb
class PointTransactionPolicy < ApplicationPolicy
  # Les transactions sont gérées via le child — on délègue à ChildPolicy
  def index?  = record.child.user_id == user.id || admin?
  def create? = record.child.user_id == user.id || admin?
end
