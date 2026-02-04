class TelegramController < ApplicationController
  # Ignora verificações de segurança padrão para permitir que o Telegram converse conosco
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def webhook
    # 1. Extrair dados da mensagem
    message = params['message']
    
    # Proteção: Se for uma edição de mensagem ou algo sem texto, ignora
    return head :ok unless message && message['text']

    telegram_id = message['from']['id']
    text = message['text']
    chat_id = message['chat']['id']

    # 2. Encontrar o usuário (Pelo ID dele ou do cônjuge)
    user = User.find_by(telegram_id: telegram_id) || User.find_by(spouse_telegram_id: telegram_id)

    # 3. Processar a lógica
    if user
      response_text = handle_message(text, user)
    else
      response_text = "🚫 <b>Não te conheço!</b>\n\nO teu ID do Telegram é: <code>#{telegram_id}</code>\n\nVai ao site, clica em 'Minha Conta' e cola este número lá."
    end

    # 4. Responder
    send_message(chat_id, response_text)

    head :ok
  end

  private

  # 🧠 CÉREBRO DO ROBÔ
  def handle_message(text, user)
    case text.downcase
    
    # --- COMANDO 1: DEFINIR META (/meta 3000) ---
    when /^\/meta\s+(\d+)/
      valor = text.match(/(\d+)/)[1].to_f
      user.update(budget: valor)
      "✅ <b>Meta Atualizada!</b>\nAgora o teu objetivo mensal é #{format_money(valor)}."

    # --- COMANDO 2: VER HISTÓRICO (/historico) ---
    when /^\/historico/
      mes_passado = 1.month.ago
      gasto = user.expenses.where(date: mes_passado.all_month).sum(:amount)
      "📅 <b>Resumo de #{I18n.l(mes_passado, format: '%B/%Y')}</b>\n\n💸 Total gasto: #{format_money(gasto)}"

    # --- COMANDO 3: SALDO ATUAL (/saldo) ---
    when "/saldo", "/resumo", "/start"
      saldo = user.remaining_balance
      gasto = user.current_month_spending
      meta = user.monthly_budget
      
      msg = "📊 <b>Resumo de #{I18n.l(Date.today, format: '%B')}</b>\n\n"
      msg += "🎯 Meta: #{format_money(meta)}\n"
      msg += "💸 Gastos: #{format_money(gasto)}\n"
      msg += "💰 <b>Saldo: #{format_money(saldo)}</b>\n\n"
      
      if meta > 0 && gasto > meta
        msg += "🚨 <b>ALERTA:</b> Estouraste o orçamento!"
      elsif meta > 0 && (gasto / meta) > 0.9
        msg += "⚠️ <b>Atenção:</b> Já gastaste 90% da meta."
      end
      
      msg

    # --- COMANDO 4: REGISTRAR GASTO (50 pizza) ---
    # Aceita ponto ou vírgula (50.50 ou 50,50)
    when /^(\d+([.,]\d{1,2})?)\s+(.+)$/
      # Tratamento do valor (troca vírgula por ponto)
      amount_str = text.match(/^(\d+([.,]\d{1,2})?)/)[1]
      amount = amount_str.gsub(',', '.').to_f
      
      # Tratamento da descrição e categoria
      raw_description = text.sub(amount_str, '').strip
      
      # Tenta adivinhar a categoria pela primeira palavra (ex: "Uber" -> "Transporte")
      first_word = raw_description.split.first
      category_obj = user.categories.where("LOWER(name) = ?", first_word.downcase).first
      
      # Se não achar categoria exata, usa "Outros"
      category_name = category_obj ? category_obj.name : "Outros"

      # Salva no banco
      user.expenses.create!(
        amount: amount, 
        description: raw_description, 
        category: category_name, 
        date: Date.current
      )
      
      "✅ <b>Gasto Registrado!</b>\n" \
      "#{raw_description} (#{category_name})\n" \
      "Valor: #{format_money(amount)}\n\n" \
      "💰 Restam: #{format_money(user.remaining_balance)}"
    
    # --- MENSAGEM DE AJUDA ---
    else
      "🤖 <b>Não entendi. Tenta assim:</b>\n\n" \
      "🍕 <code>50 pizza</code> (Registrar gasto)\n" \
      "📊 <code>/saldo</code> (Ver resumo)\n" \
      "🎯 <code>/meta 2000</code> (Definir meta)\n" \
      "📅 <code>/historico</code> (Ver mês passado)"
    end
  end

  # Helper para formatar dinheiro (R$)
  def format_money(value)
    ActionController::Base.helpers.number_to_currency(value, unit: "R$ ", separator: ",", delimiter: ".")
  end

  # Envio da mensagem via Faraday
  def send_message(chat_id, text)
    token = Rails.application.credentials.telegram_bot_token
    return unless token # Evita erro se não tiver token configurado

    url = "https://api.telegram.org/bot#{token}/sendMessage"
    
    Faraday.post(
      url, 
      { 
        chat_id: chat_id, 
        text: text, 
        parse_mode: 'HTML' # Permite usar negrito (<b>) e código (<code>)
      }.to_json, 
      'Content-Type' => 'application/json'
    )
  rescue StandardError => e
    Rails.logger.error "Erro ao enviar mensagem Telegram: #{e.message}"
  end
end