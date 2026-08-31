# app/controllers/children_controller.rb
class ChildrenController < ApplicationController
  before_action :set_child, only: %i[show edit update destroy stats]

  def index
    @children = policy_scope(Child)
  end

  def show
    @child_items = @child.child_items
                         .includes(:item)
                         .joins(:item)
                         .order("child_items.active DESC, items.category, items.name")
  end

  def stats
    @stats = ChildStats.new(@child)
  end

  def new
    @child = Child.new
    authorize @child
  end

  def create
    @child = current_user.children.build(child_params)
    authorize @child

    if @child.save
      redirect_to @child, notice: "Enfant ajouté avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @child.update(child_params)
      redirect_to @child, notice: "Profil mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @child.destroy
    redirect_to children_path, notice: "Profil supprimé."
  end

  private

  def set_child
    @child = Child.find(params[:id])
    authorize @child
  end

  def child_params
    params.require(:child).permit(:first_name, :avatar_color)
  end
end
