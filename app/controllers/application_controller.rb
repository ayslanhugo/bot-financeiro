class ApplicationController < ActionController::Base
  # Garante que só usuários logados acessam o sistema (exceto login/cadastro)
  before_action :authenticate_user!
  
  # Configura o Devise para aceitar o campo telegram_id
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # Permite salvar telegram_id na hora de editar o perfil ("account_update")
    devise_parameter_sanitizer.permit(:account_update, keys: [:telegram_id])
    
    # Se quiseres pedir no cadastro também, descomenta a linha abaixo:
    # devise_parameter_sanitizer.permit(:sign_up, keys: [:telegram_id])
  end
end