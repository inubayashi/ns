#coding : utf-8
class DishesController < ApplicationController
  def index    
    @dishes = Dish.all
    @foodstuffs = Foodstuff.all
    if(session[:status] != nil)
      @dishes = Dish.where(category: session[:status])
    else
      @dishes = Dish.all
    end
  end
  
  def top
    @foodstuffs = Foodstuff.all
    session.delete(:status)
    session.delete(:order)
    @dishes = Dish.all
    if(session[:status] != nil)
      @dishes = Dish.where(category: session[:status])
    else
      @dishes = Dish.all
    end
    render "index"
  end

  def show
    @dish = Dish.find(params[:id])
    if params[:format].in?(["jpg", "png", "gif"])
      send_image
    else
      render "dishes/show"
    end
  end

  def search
    @dishes = Dish.search(params[:q])
    @foodstuffs = Foodstuff.all
    @checked = params[:foodstuffs]
p "----------------------------check"
p @checked
    if @checked.present?
    ser = Dish.pluck :name
    @checked.each do |check|
      food = Dish.joins(:foodstuffs).where("foodstuffs.name = ?", check).uniq
      allergy = food.pluck("dishes.name")
      ser = ser - allergy
      
    end
    @dishes = Dish.where(name: ser.map{ |abc| abc})
    end
    render "index"
  end

  def order
    session[session[:status]] = Dish.find(params[:id])
    @dish = Dish.find(params[:id])
    case @dish.category
      when "staple"
        session[:order].staple_id = @dish.id
      when "main"
        session[:order].main_id = @dish.id
      when "sub"
        session[:order].sub_id = @dish.id
    end
    redirect_to :controller=>"orders", :action=>"new", :name => "select" 
    
  end


  private
  def send_image
    if @dish.image.present?
      send_data @dish.image.data,
        type: @dish.image.content_type, disposition: "inline"
    end
  end
end
