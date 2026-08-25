# app/policies/child_item_policy.rb
class ChildItemPolicy < ApplicationPolicy
  def index?   = true
  def show?    = parent_owner_or_admin?
  def create?  = parent_owner_or_admin?
  def update?  = parent_owner_or_admin?
  def destroy? = parent_owner_or_admin?

  private
  def parent_owner_or_admin?
    admin? || record.child.user_id == user.id
  end
end
