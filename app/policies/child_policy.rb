class ChildPolicy < ApplicationPolicy
  def index?   = true
  def show?    = owner_or_admin?
  def stats?   = owner_or_admin?    # ← ajouter
  def create?  = true
  def update?  = owner_or_admin?
  def destroy? = owner_or_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.all : scope.where(user: user)
    end
  end

  private
  def owner_or_admin? = admin? || record.user_id == user.id
end
