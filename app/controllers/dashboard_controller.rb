# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    @children = policy_scope(Child).includes(:child_items)
  end
end
