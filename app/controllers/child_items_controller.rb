# app/controllers/child_items_controller.rb
class ChildItemsController < ApplicationController
  before_action :set_child,      only: %i[new create bulk_edit bulk_update]
  before_action :set_child_item, only: %i[edit update destroy]

  # ── Assignation en masse ─────────────────────────────────────
  def bulk_edit
    @items       = policy_scope(Item).order(:category, :name)
    @child_items = @child.child_items.index_by(&:item_id)
    @checked_ids = @child.child_items.active.pluck(:item_id)
  end

  def bulk_update
    selected = Array(params[:item_ids]).map(&:to_i)
    existing = @child.child_items.index_by(&:item_id)

    added = reactivated = deactivated = removed = 0

    ActiveRecord::Base.transaction do
      selected.each do |item_id|
        ci = existing[item_id]
        if ci.nil?
          @child.child_items.create!(item_id: item_id)
          added += 1
        elsif !ci.active?
          ci.update!(active: true)
          reactivated += 1
        end
      end

      existing.each do |item_id, ci|
        next if selected.include?(item_id)

        if ci.day_entries.exists?
          # Historique présent : on désactive, on ne détruit pas
          if ci.active?
            ci.update!(active: false)
            deactivated += 1
          end
        else
          ci.destroy
          removed += 1
        end
      end
    end

    redirect_to child_path(@child),
      notice: bulk_message(added, reactivated, deactivated, removed)
  end

  # ── CRUD unitaire ────────────────────────────────────────────
  def new
    @child_item = @child.child_items.build
    authorize @child_item
    @available_items = available_items
  end

  def create
    @child_item = @child.child_items.build(child_item_params)
    authorize @child_item

    if @child_item.save
      redirect_to @child, notice: "Item assigné à #{@child.first_name}."
    else
      @available_items = available_items
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @child = @child_item.child
  end

  def update
    if @child_item.update(child_item_params)
      redirect_to @child_item.child, notice: "Valeurs mises à jour."
    else
      @child = @child_item.child
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    child = @child_item.child
    if @child_item.day_entries.exists?
      @child_item.update!(active: false)
      redirect_to child, notice: "Item désactivé — son historique est conservé."
    else
      @child_item.destroy
      redirect_to child, notice: "Item retiré."
    end
  end

  private

  def set_child
    @child = Child.find(params[:child_id])
    authorize @child, :show?
  end

  def set_child_item
    @child_item = ChildItem.find(params[:id])
    authorize @child_item
  end

  def available_items
    policy_scope(Item).active
                      .where.not(id: @child.items.select(:id))
                      .order(:category, :name)
  end

  def child_item_params
    params.require(:child_item)
          .permit(:item_id, :green_points, :yellow_points, :red_points, :active)
  end

  def bulk_message(added, reactivated, deactivated, removed)
    parts = []
    parts << "#{added} assigné#{'s' if added > 1}"               if added.positive?
    parts << "#{reactivated} réactivé#{'s' if reactivated > 1}"  if reactivated.positive?
    parts << "#{deactivated} désactivé#{'s' if deactivated > 1}" if deactivated.positive?
    parts << "#{removed} retiré#{'s' if removed > 1}"            if removed.positive?
    parts.empty? ? "Aucun changement." : "#{parts.join(', ')}."
  end
end
