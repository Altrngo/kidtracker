# app/controllers/privileges_controller.rb
class PrivilegesController < ApplicationController
  before_action :set_privilege, only: %i[edit update destroy]

  def index
    @privileges = policy_scope(Privilege).active.order(:point_cost)
  end

  def new
    @privilege = Privilege.new
    authorize @privilege
  end

  def create
    @privilege = current_user.privileges.build(privilege_params)
    authorize @privilege

    if @privilege.save
      redirect_to privileges_path, notice: "Privilège créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @privilege.update(privilege_params)
      redirect_to privileges_path, notice: "Privilège mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @privilege.destroy
    redirect_to privileges_path, notice: "Privilège supprimé."
  end

  private

  def set_privilege
    @privilege = Privilege.find(params[:id])
    authorize @privilege
  end

  def privilege_params
    params.require(:privilege).permit(:name, :point_cost, :active)
  end
end
