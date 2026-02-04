module Telegram
  class MessageProcessorService
    # Regex para capturar: Valor (decimal), Descrição (texto) e Categoria (opcional)
    REGEX_FORMAT = /^(?<amount>\d+(?:[.,]\d{1,2})?)\s+(?<description>.+?)(?:\s+(?<category>\w+))?$/i

    def initialize(payload)
      @payload = payload
      @message = payload['message'] || {}
      @chat_id = @message.dig('chat', 'id')
      @text = @message['text']
      @telegram_user_id = @message.dig('from', 'id').to_s
    end

    def call
      return unless @text.present?

      # 1. Busca usuário (Titular ou Cônjuge)
      user = User.where("telegram_id = ? OR spouse_telegram_id = ?", @telegram_user_id, @telegram_user_id).first
      
      # Se não achar usuário, retorna mensagem de erro
      return "🚫 Usuário não identificado. Vincule seu ID (#{@telegram_user_id}) no site." unless user

      # 2. Roteador de Comandos
      case @text.downcase.strip
      when '/start', 'oi', 'ola', 'ajuda'
        welcome_message
      when '/desfazer', 'desfazer', 'undo'
        delete_last_expense(user)
      when '/relatorio', 'resumo', 'total'
        generate_monthly_report(user)
      else
        # 3. Se não for comando, tenta registrar despesa
        process_expense_creation(user)
      end
    end

    private

    def process_expense_creation(user)
      match = @text.match(REGEX_FORMAT)
      return "⚠️ Não entendi.\n\nUse: <b>Valor Descrição Categoria</b>\nEx: <code>50.00 Pizza Lazer</code>\n\nOu use <b>/desfazer</b> para apagar." unless match

      save_expense(user, match)
    end

    def save_expense(user, match)
      amount = match[:amount].tr(',', '.').to_f
      category = (match[:category] || 'Outros').capitalize
      description = match[:description]

      Expense.create!(
        user: user,
        amount: amount,
        description: description,
        category: category,
        date: Time.current
      )

      # Cálculos para o feedback
      meta = user.monthly_budget
      saldo = user.remaining_balance
      status = saldo.negative? ? "🔴" : "🟢"

      # HEREDOC corrigido: Agora usamos a variável 'meta' que estava esquecida
      <<~HEREDOC
        ✅ <b>Gasto Salvo!</b>
        💸 #{description}: R$ #{amount}
        📂 #{category}
        
        📊 <b>Meta:</b> R$ #{meta}
        #{status} <b>Restam: R$ #{saldo.round(2)}</b>
      HEREDOC
    end

    def delete_last_expense(user)
      last_expense = user.expenses.order(created_at: :desc).first

      return "🤷‍♂️ Nenhuma despesa recente para apagar." unless last_expense

      desc = last_expense.description
      val = last_expense.amount
      
      last_expense.destroy

      <<~HEREDOC
        🗑️ <b>Despesa Apagada!</b>
        ❌ #{desc} (R$ #{val})
        
        💰 <b>Saldo corrigido: R$ #{user.remaining_balance.round(2)}</b>
      HEREDOC
    end

    def generate_monthly_report(user)
      expenses = user.expenses.where(date: Time.current.all_month).group(:category).sum(:amount)
      
      return "📭 Nenhuma despesa registrada neste mês." if expenses.empty?

      lista = expenses.map { |cat, val| "▫️ <b>#{cat}:</b> R$ #{val}" }.join("\n")
      
      <<~HEREDOC
        📊 <b>Relatório Mensal</b>
        
        #{lista}
        
        ➖➖➖➖➖➖
        💰 <b>Total Gasto:</b> R$ #{user.current_month_spending}
        🎯 <b>Meta:</b> R$ #{user.monthly_budget}
      HEREDOC
    end

    def welcome_message
      <<~HEREDOC
        👋 <b>Olá! Sou o Financeiro Bot.</b>
        
        📝 <b>Como usar:</b>
        Envie: <code>Valor Descrição Categoria</code>
        Ex: <code>20 Padaria Alimentacao</code>
        
        ⚙️ <b>Comandos:</b>
        /relatorio - Ver gastos por categoria
        /desfazer - Apagar o último gasto
      HEREDOC
    end
  end
end