module Booking
  class HotelResponse
    include Mongoid::Document
    include Mongoid::Timestamps

    field :_id, type: Integer, default: ->{ self.hotel_id}

    def hotel
      @hotel ||= Hotel.find_by_booking_hotel_id hotel_id
    end

    def hotel_id
      self['hotel_id']
    end

    def total
      
    end

    def price_in_currency
      other_currency[0]
    end

    def other_currency
      self['other_currency']
    end

    def other_currency?
      other_currency
    end

    def min_price
      other_currency? ? price_in_currency['min_total_price'] : self['min_total_price']
    end

    def max_price
      other_currency? ? price_in_currency['max_total_price'] : self['max_total_price']
    end

    def local_min_price
      self['min_total_price']
    end

    def local_max_price
      self['max_total_price']
    end

    def currency
      self['currency_code']
    end

    def rooms
    end

    def rooms_count
      self['available_rooms']
    end


    def commonize
      {
        provider: :booking,
        provider_hotel_id: id,
        room_count: rooms_count,
        min_price: min_price,
        max_price: max_price,
        rooms: nil
      }
    rescue
      Log.error "Booking Hotel #{id} failed to convert"
      nil
    end


  end

end