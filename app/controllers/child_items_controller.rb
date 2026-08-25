# app/controllers/child_items_controller.rb
class ChildItemsController < ApplicationController
  before_action :set_child,      only: %i[new create]
  before_action :set_child_item, only: %i[edit update destroy]

  def new
    @child_item = @child.child_items.build
    authorize @child_item
    # Items déjà assignés exclus de la liste
    @available_items = policy_scope(Item).active
                                         .where.not(id: @child.items.select(:id))
                                         .order(:category, :name)
  end

  def create
    @child_item = @child.child_items.build(child_item_params)
    authorize @child_item

    if @child_item.save
      redirect_to @child, notice: "Item assigné à #{@child.first_name}."
    else
      @available_items = policy_scope(Item).active
                                           .where.not(id: @child.items.select(:id))
                                           .order(:category, :name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @child = @child_item.child
  end

  def update
    if @child_item.update(child_item_params)
      redirect_to @child_item.child, notice: "Valeurs des smileys mises à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    child = @child_item.child
    @child_item.destroy
    redirect_to child, notice: "Item retiré."
  end

  private

  def set_child
    @child = Child.find(params[:child_id])
  end

  def set_child_item
    @child_item = ChildItem.find(params[:id])
    authorize @child_item
  end

  def child_item_params
    params.require(:child_item).permit(:item_id, :green_points, :yellow_points, :red_points, :active)
  end
end
