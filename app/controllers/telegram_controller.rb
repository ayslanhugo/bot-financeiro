class TelegramController < ApplicationController
  skip_before_action :verify_authenticity_token

  def webhook
    # 1. Recebe a mensagem do Telegram
    payload = params[:telegram]
    
    # 2. Processa a lógica (Salvar gasto, gerar relatório, etc)
    # O Service retorna o texto da resposta
    response_message = Telegram::MessageProcessorService.new(payload).call

    # 3. Se o Service gerou uma resposta, envia de volta ao usuário
    if response_message
      send_message(payload['message']['chat']['id'], response_message)
    end

    head :ok
  end

  private

  def send_message(chat_id, text)
    # Pega o token salvo nas credenciais
    token = Rails.application.credentials.telegram_bot_token
    
    # Monta a URL da API
    url = "https://api.telegram.org/bot#{token}/sendMessage"
    
    # Envia o POST usando Faraday (agora com suporte a HTML!)
    Faraday.post(
      url, 
      { 
        chat_id: chat_id, 
        text: text, 
        parse_mode: 'HTML' 
      }.to_json, 
      'Content-Type' => 'application/json'
    )
  end
end