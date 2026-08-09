class Api::ExpensesController < ApplicationController
  def index
    expenses = Expense.includes(:category).order(date: :desc)

    if params[:year].present? && params[:month].present?
      begin
        year = Integer(params[:year])
        month = Integer(params[:month])
      rescue ArgumentError
        return render json: { error: "Year and month must be valid numbers"},
                      status: :bad_request
      end
      unless month.between?(1, 12)
        return render json: { error: "Month must be between 1 and 12"},
                      status: :bad_request
      end
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      expenses = expenses.where(date: start_date..end_date)
    end

    render json: expenses.map { |expense| format_expense(expense) }
  end

  def create
    expense = Expense.new(expense_params)

    if expense.save
      render json: format_expense(expense), status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    expense = Expense.find(params[:id])

    if expense.update(expense_params)
      render json: format_expense(expense)
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    expense = Expense.find(params[:id])
    expense.destroy
    head :no_content
  end

  private

  def expense_params
    params.require(:expense).permit(:description, :amount, :category_id, :date)
  end

  def format_expense(expense)
    {
      id: expense.id,
      description: expense.description,
      amount: expense.amount,
      category: expense.category.name,
      date: expense.date&.iso8601,
      created_at: expense.created_at&.iso8601,
      updated_at: expense.updated_at&.iso8601
    }
  end
end
