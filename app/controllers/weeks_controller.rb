# app/controllers/weeks_controller.rb
class WeeksController < ApplicationController
  before_action :set_child
  before_action :set_week, only: %i[show finalize]

  def index
    @weeks        = @child.weeks.recent
    @current_week = Week.current_for(@child)
  end

  def show
    @entries_by_item_and_day = @week.day_entries
                                    .includes(child_item: :item)
                                    .each_with_object({}) do |entry, hash|
      hash[[entry.child_item_id, entry.day_of_week]] = entry
    end

    @child_items = @child.child_items.active
                         .includes(:item)
                         .joins(:item)
                         .order("items.category, items.name")
  end

  def finalize
    if @week.finalized?
      redirect_to child_week_path(@child, @week), alert: "Cette semaine est déjà finalisée."
    else
      @week.finalize!(current_user)   # ← traçabilité de l'auteur
      redirect_to child_weeks_path(@child),
        notice: "Semaine finalisée — #{@week.week_score} points ajoutés."
    end
  end

  private

  def set_child
    @child = Child.find(params[:child_id])
    authorize @child, :show?
  end

  def set_week
    @week = @child.weeks.find(params[:id])
  end
end
