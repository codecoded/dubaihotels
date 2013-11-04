module Expedia
  class HotelResponse
    include Mongoid::Document
    include Mongoid::Timestamps

    embeds_many :images, class_name: 'Expedia::Image'

    field :_id, type: Integer, default: ->{ self.hotelId}

    def total
      charge_info['@total'] if charge_info
    end

    def currency
      charge_info['@currencyCode'] if charge_info
    end

    def charge_info
      rate_info['ChargeableRateInfo'] if rate_info
    end

    def rate_info
      top_room_rate['RateInfos']['RateInfo'] if top_room_rate
    end

    def top_room_rate
      room_rates[0] if room_rates
    end

    def room_rate_details
      self['RoomRateDetailsList']['RoomRateDetails'] if self['RoomRateDetailsList']
    end

    def rooms
      return [] unless room_rate_details
      @rooms ||= if room_list?
        room_rate_details.map {|room| Expedia::Room.new room}
      else
        [Expedia::Room.new(room_rate_details)]
      end
    end

    def rooms_count
      rooms.count
    end

    def room_list?
      room_rate_details.is_a? Array
    end

    def room_rates
      rooms.map{|r| r.total.to_f}.sort
    end


    # def images
    #   return unless self.HotelImages
    #   self.HotelImages['HotelImage']
    # end

    def commonize
      {
        provider: :expedia,
        provider_hotel_id: id,
        room_count: rooms_count,
        min_price: room_rates[0],
        max_price: room_rates[-1],
        rooms: rooms.map(&:commonize)
      }
    rescue
      Log.error "Hotel #{id} failed to convert"
      nil
    end

    private 

    def self.sort_lookup(sort)
      sort_options[sort.to_s.downcase]
    end

    def self.sort_options
      {
        'exact' => 'NO_SORT',
        'popularity' => 'CITY_VALUE',
        'value' => 'OVERALL_VALUE',
        'promo' => 'PROMO', 
        'price' => 'PRICE',
        'price_reverse' => 'PRICE_REVERSE',
        'prive_average' => 'PRIVE_AVERAGE',
        'rating' => 'QUALITY', 
        'rating_reverse' => 'QUALITY_REVERSE',
        'a_z' => 'ALPHA',
        'proximity' => 'PROXIMITY',
        'postal_code' => 'POSTAL_CODE'
      }
    end    

    def method_missing(method, *args, &block)
      self[method.to_s]
    end

  end

end
