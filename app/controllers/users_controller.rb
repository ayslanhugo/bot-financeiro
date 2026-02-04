class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    # Apenas exibe a página (o redirect está na view, lembra?)
  end

  def edit
    # Apenas exibe o formulário para @user
  end

  def update
    if @user.update(user_params)
      # Se salvar com sucesso, volta para a página de perfil com mensagem verde
      redirect_to edit_profile_path, notice: "Configurações atualizadas com sucesso!"
    else
      # Se der erro (ex: email inválido), mostra o formulário de novo
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    # Aqui está o segredo! 
    # Adicionamos :spouse_telegram_id na lista para o Rails deixar salvar.
    params.require(:user).permit(:email, :telegram_id, :spouse_telegram_id, :budget)
  end
end