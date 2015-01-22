# coding: utf-8
class Admin::OrdersController < Admin::Base
  def index
    now_t = Date.today
    now_new_t = Time.local(now_t.year, now_t.month, now_t.day, 0, 0, 0).strftime("%Y-%m-%d %H:%M:%S")
    now_end_t = Time.local(now_t.year, now_t.month, now_t.day, 23, 59, 59).strftime("%Y-%m-%d %H:%M:%S")
    @today_order = Order.order("receive_date").find(:all, :conditions => ["receive_date > ? and receive_date < ?", now_new_t.to_s, now_end_t.to_s])
    @size = Array.new
    @staple = Array.new
    @main = Array.new
    @sub = Array.new
    @today_order.each do |order|
      case order.lunchbox_id
      when 1
        @size.push("大")
      when 2
        @size.push("普通")
      when 3
        @size.push("小")
      end
      @staple.push(Dish.find(order.staple_id).name)
      @main.push(Dish.find(order.main_id).name)
      @sub.push(Dish.find(order.sub_id).name)
    end

    @future_order = Order.paginate(
      :conditions => ["receive_date > ?", now_end_t.to_s],
      :page => params[:page],
      :order => 'receive_date',
      :per_page => 10
    )
    @a_size = Array.new
    @a_staple = Array.new
    @a_main = Array.new
    @a_sub = Array.new
    @future_order.each do |order|
      case order.lunchbox_id
      when 1
        @a_size.push("大")
      when 2
        @a_size.push("普通")
      when 3
        @a_size.push("小")
      end
      @a_staple.push(Dish.find(order.staple_id).name)
      @a_main.push(Dish.find(order.main_id).name)
      @a_sub.push(Dish.find(order.sub_id).name)
    end
  end

  def all_order
    @all_order = Order.paginate(
      :page => params[:page],
      :order => 'receive_date',
      :per_page => 10
    )
    @size = Array.new
    @staple = Array.new
    @main = Array.new
    @sub = Array.new
    @all_order.each do |order|
      case order.lunchbox_id
      when 1
        @size.push("大")
      when 2
        @size.push("普通")
      when 3
        @size.push("小")
      end
      @staple.push(Dish.find(order.staple_id).name)
      @main.push(Dish.find(order.main_id).name)
      @sub.push(Dish.find(order.sub_id).name)
    end
  end

  def show
    session[:date] = Order.find_by_id(params[:id])
    @order = Order.find(params[:id])
    @staple = Dish.find(@order.staple_id)
    @main = Dish.find(@order.main_id)
    @sub = Dish.find(@order.sub_id)
    session.delete(:order)
  end

  def edit
    if session[:order].present?
      @order = session[:order]
    else
      @order = Order.find(params[:id])
      session[:order] = @order
    end

    @size = Array.new
    @explanation = Array.new
    Lunchbox.all.each do |lunchbox|
      @size.push([lunchbox.size, lunchbox.id])
      @explanation.push(lunchbox.explanation)
    end
session[:order] = @order
  end

  def check
    @order = Order.find(session[:order][:id])
    @order.assign_attributes(params[:order])
    session[:order] = @order
    if params[:changedate]
      @lunchboxes = Lunchbox.all
      @size = Array.new
      @explanation = Array.new
      @lunchboxes.each do |lunchbox|
        @size.push([lunchbox.size, lunchbox.id])
        @explanation.push(lunchbox.explanation)
      end
      render "edit"
    elsif params[:staple]
      session[:status] = :staple
      redirect_to :controller=>"dishes", :action=>"index"
    elsif params[:main]
      session[:status] = :main
      redirect_to :controller=>"dishes", :action=>"index"
    elsif params[:sub]
      session[:status] = :sub
      redirect_to :controller=>"dishes", :action=>"index"
    else
     if @order.valid?
      @lunchbox = Lunchbox.find(@order.lunchbox_id)
      @staple = Dish.find(@order.staple_id)
      @main = Dish.find(@order.main_id)
      @sub = Dish.find(@order.sub_id)
      @price = (@staple.yen + @main.yen + @sub.yen) * @lunchbox.capacity
      @kcal = (@staple.kcal + @main.kcal + @sub.kcal) * @lunchbox.capacity
      @num = @order.num
      @sum = @price * @order.num
      @date = @order.receive_date.to_s.split(" ")[0]

      @max= 10000
       @staple_stock = Stock.where(dish_id: "#{@order.staple_id}", date: "#{@date}")
       @max = @staple_stock[0].stock if @max > @staple_stock[0].stock
       @main_stock =Stock.where(dish_id: "#{@order.main_id}", date: "#{@date}")
       @max = @main_stock[0].stock if @max > @main_stock[0].stock
       @sub_stock =Stock.where(dish_id: "#{@order.sub_id}", date: "#{@date}")
       @max = @sub_stock[0].stock if @max > @sub_stock[0].stock
       
       
       @max = @max - @lunchbox.capacity * @order.num
      render  :action =>"check"
     else
      redirect_to :action=> "edit"
    end
    end
  end

  def update
    @order = session[:order]
    if session[:date][:staple_id] != @order.staple_id
      @old_date = session[:date][:receive_date].to_s.split(" ")[0]
      @st = Stock.where("dish_id = ? AND date = ? ",session[:date][:staple_id], @old_date)
      @st[0].stock = @st[0].stock + session[:date].lunchbox.capacity * session[:date].num
      @st[0].save
    elsif session[:date][:staple_id] == @order.staple_id
      @old_date = session[:date][:receive_date].to_s.split(" ")[0]
      @st = Stock.where("dish_id = ? AND date = ? ",session[:date][:staple_id], @old_date)
      @st[0].stock = @st[0].stock + session[:date].lunchbox.capacity * session[:date].num
      @st[0].save
    end
    if session[:date][:main_id] != @order.main_id
      @old_date = session[:date][:receive_date].to_s.split(" ")[0]
      @st = Stock.where("dish_id = ? AND date = ? ",session[:date][:main_id], @old_date)
      @st[0].stock = @st[0].stock + session[:date].lunchbox.capacity * session[:date].num
      @st[0].save
    elsif session[:date][:main_id] == @order.main_id
      @old_date = session[:date][:receive_date].to_s.split(" ")[0]
      @st = Stock.where("dish_id = ? AND date = ? ",session[:date][:main_id], @old_date)
      @st[0].stock = @st[0].stock + session[:date].lunchbox.capacity * session[:date].num
      @st[0].save
    end
    if session[:date][:sub_id] != @order.sub_id
      @old_date = session[:date][:receive_date].to_s.split(" ")[0]
      @st = Stock.where("dish_id = ? AND date = ? ",session[:date][:sub_id], @old_date)
      @st[0].stock = @st[0].stock + session[:date].lunchbox.capacity * session[:date].num
      @st[0].save
    elsif session[:date][:sub_id] == @order.sub_id
      @old_date = session[:date][:receive_date].to_s.split(" ")[0]
      @st = Stock.where("dish_id = ? AND date = ? ",session[:date][:sub_id], @old_date)
      @st[0].stock = @st[0].stock + session[:date].lunchbox.capacity * session[:date].num
      @st[0].save
    end

      @order.dishes.destroy_all #料理の関係削除

      select3 = [@order.staple_id, @order.main_id, @order.sub_id]
      select3.each do |sel|
      dishe = Dish.find(sel)
      dishe.orders << @order
      end

    if @order.save
      @order.dishes.all.each do |dish|
      @date=@order.receive_date.to_s.split(" ")[0]
      @stock = Stock.where(dish_id: "#{dish.id}", date: "#{@date}")
      @stock[0].stock = @stock[0].stock - @order.lunchbox.capacity * @order.num
      @stock[0].save
      end
      session.delete(:order)
      redirect_to [:admin, @order], notice: "予約情報を更新しました。"
    else
      render  :action => "edit"
    end
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
    redirect_to :admin_orders, notice: "予約情報を削除しました。"
  end
end
