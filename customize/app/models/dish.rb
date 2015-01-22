class Dish < ActiveRecord::Base
  attr_accessible :name, :kcal, :yen, :genra, :category, :image_attributes, :visible

  has_one :image, class_name: "DishImage", dependent: :destroy
  has_one :stock, dependent: :destroy
  has_many :customs
  has_many :orders,  through: :customs

  has_many :recipes
  has_many :foodstuffs, through: :recipes

  accepts_nested_attributes_for :image

  class << self
    def search(query)
      if query.present?
        if (Foodstuff.find_by_name("#{query}")).present? then
          rel = Foodstuff.find_by_name("#{query}")
          rel = rel.dishes.all
        elsif (Dish.where("name LIKE ?", "%#{query}%")).present? then
          rel = Dish.where("name LIKE ?", "%#{query}%")
        elsif (Foodstuff.find_by_name("#{query}")) &&
                 (rel.where("name LIKE ?", "%#{query}%")).blank? then
          rel
        end
      end
      rel
    end
  end
end
