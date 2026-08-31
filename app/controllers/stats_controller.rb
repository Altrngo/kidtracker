# app/controllers/stats_controller.rb
class StatsController < ApplicationController
  def index
    @children = policy_scope(Child).includes(:child_items)
    @stats    = @children.map { |c| [c, ChildStats.new(c)] }
  end
end
