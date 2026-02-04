require "csv"

class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[ show edit update destroy ]

  def index
    # 1. Lógica de Navegação no Tempo
    if params[:month].present?
      @current_date = Date.parse(params[:month]) rescue Date.current
    else
      @current_date = Date.current
    end

    range = @current_date.all_month
    
    # 👇 A CORREÇÃO ESTÁ AQUI: .reorder(nil)
    # Isso garante que não há ordenação oculta atrapalhando os gráficos
    expenses_in_month = current_user.expenses.where(date: range).reorder(nil)

    # 2. Gráficos (Agora funcionam sem erro de agrupamento)
    @expenses_by_category = expenses_in_month.group(:category).sum(:amount)
    @expenses_by_day      = expenses_in_month.group_by_day(:date).sum(:amount)

    # 3. Totais
    @total_gasto = expenses_in_month.sum(:amount)
    @orcamento   = current_user.monthly_budget
    @saldo       = @orcamento - @total_gasto

    # 4. Lista Visual (Aqui sim, queremos ordenar por data)
    @expenses = expenses_in_month.order(date: :desc)

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv(@expenses), filename: "gastos-#{@current_date.strftime('%m-%Y')}.csv" }
    end
  end

  def new
    @expense = Expense.new
  end

  def edit
  end

  def create
    @expense = current_user.expenses.build(expense_params)
    @expense.date ||= Time.current

    if @expense.save
      redirect_to root_path, notice: "Despesa criada!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      redirect_to root_path, notice: "Atualizado!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy!
    redirect_to root_path, notice: "Apagado!"
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:description, :amount, :category, :date)
  end

  def generate_csv(expenses)
    CSV.generate(headers: true, col_sep: ";") do |csv|
      csv << ["Data", "Descrição", "Categoria", "Valor"]
      expenses.each do |e|
        csv << [e.date&.strftime("%d/%m/%Y"), e.description, e.category, e.amount.to_s.tr('.', ',')]
      end
    end
  end
end