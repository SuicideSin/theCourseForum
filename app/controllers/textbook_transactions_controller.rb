class TextbookTransactionsController < ApplicationController

  def index
    @textbook_transactions = TextbookTransaction.active.map do |tt|
      {
        :id => tt.id,
        :price => "$" + tt.price.to_s,
        :courses => tt.book.sections.map(&:course).uniq.map(&:mnemonic_number).join(", "),
        :title => tt.book.title,
        :book_id => tt.book_id,
        :author => tt.book.author,
        :condition => tt.condition,
        :notes => tt.notes,
        :end_date => (tt.created_at + 3.days).localtime.strftime("%b %d, %I:%M %p")
      }
    end
  end

  def books
    @books = Book.order("RAND()").map do |book|
      {
        :image => (book.small_image_link ? book.small_image_link : "/assets/icons/no_book.png"),
        :title => book.title,
        :id => book.id
      }
    end
  end

  def search_book_titles
    query = params[:query]

    results = []
    results = Book.where("title LIKE ?", "%#{query}%").map do |book|
      {
        :book_id => book.id,
        :bookstore_used_price => book.bookstore_used_price,
        :title => book.title
      }
    end
    puts results

    render :json => [results]
  end

  def claim
    cell = params[:cellphone].strip
    current_user.update(:cellphone => cell)

    if cell.length == 10
      transaction = TextbookTransaction.active.find(params[:format])
      transaction.update(:buyer_id => current_user.id)
      transaction.update(:sold_at => Time.now)
      # RestClient.post 'http://textbelt.com/text', :number => transaction.seller.cellphone, :message => "Your posting for \"#{transaction.book.title}\" has been claimed!\nContact info: #{current_user.cellphone}"
      render :json => {
        status: "success"
      }
    else
      render :json => {
        status: "failure"
      }
    end
  end

  def create
    current_user.update(:cellphone => params[:cellphone])
    
    params[:book_id] = Book.where("title LIKE ?", params[:title]).first.id
    params[:seller_id] = current_user.id
    
    @textbook_transaction = TextbookTransaction.new(textbook_transaction_params)
    @textbook_transaction.save
    
    redirect_to :action => :index
  end

  def new
  end

  def edit
  end

  def show
  end

  def update
  end

  def destroy
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def textbook_transaction_params
      params[:textbook_transaction] = {
        :seller_id => params[:seller_id],
        :buyer_id => params[:buyer_id],
        :price => params[:price],
        :condition => params[:condition],
        :notes => params[:notes],
        :book_id => params[:book_id]
      }
      params.require(:textbook_transaction).permit(:title, :cellphone, :price, :condition, :notes, :book_id, :seller_id, :buyer_id)
    end
end