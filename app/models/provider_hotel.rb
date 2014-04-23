class ProviderHotel < ActiveRecord::Base
  attr_accessible :address, :amenities, :city, :country_code, :description, :hotel_id, :hotel_link, :latitude, :longitude, :name, :postal_code, :provider_hotel_id, :provider_id, :star_rating, :state_province, :user_rating
end