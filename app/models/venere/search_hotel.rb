module Venere
  class SearchHotel < Venere::Search

    attr_reader :ids, :responses

    DEFAULT_SLICE = 350

    def initialize(ids, search_criteria)
      super search_criteria
      @ids, @responses = ids, []
    end

    def self.search(ids, search_criteria, options={})
      new(ids, search_criteria).search(options)
    end

    def self.for_availability(hotel_id, search_criteria, options={})
      new([hotel_id], search_criteria).search(options)
    end

    def self.page_hotels(ids, search_criteria, options={}, &block)
      new(ids, search_criteria).page_hotels(options, &block)
    end

    def self.by_geo_ids(geo_ids, search_criteria, options={})
      new([geo_ids], search_criteria).by_geo_ids(options)
    end

    def self.by_geo_city_zone_ids(city_zone_ids, search_criteria, options={})
      new([city_zone_ids], search_criteria).by_geo_city_zone_ids(options)
    end

    def search(options={})
      params = search_params.merge(hotel_params)
      create_list_response Venere::Client.hotel_availability(params)
    end

    def by_geo_ids(options={})
      params = search_params.merge(geo_id_params(options))
      create_list_response Venere::Client.geo_ids_search(params)
    end

    def by_geo_city_zone_ids(options={})
      params = search_params.merge(geo_id_params(options))
      create_list_response Venere::Client.geo_city_zone_ids_search(params)
    end

    def page_hotels(options={}, &block)

      responses, slice_by = [],  (options[:slice] || DEFAULT_SLICE)

      time = Benchmark.realtime do 
        (conn = Venere::Client.http).in_parallel do 
          ids.each_slice(slice_by) do |sliced_ids|          
            Log.info "Sending request for #{sliced_ids.count} out of #{ids.count} hotels to Venere.com:\n"

            params = search_params.merge(hotel_params(sliced_ids))
            soap_envelope = Venere::Client.soap_envelope(params)  {Venere::Client.by_property(params)}
            responses << conn.post( Venere::Client.url + 'XHI_HotelAvail.soap', soap_envelope)
          end
        end
      end

      hotels = collect_hotels(concat_responses(responses))
      Log.info "Collected #{hotels.count} hotels out of #{ids.count} hotels in #{responses.count} Venere requests. Time taken: #{time}s"
      yield hotels if block_given?
    end 

    def concat_responses(responses)
      responses.map {|response| create_list_response Nokogiri.XML(response.body).remove_namespaces!}
    end

    def collect_hotels(list_responses)
      list_responses.flat_map {|list_response| list_response.hotels}
    end

    def hotel_params(custom_ids=nil)
      {
        hotel_ids: (custom_ids || ids).join(' ')
      }
    end

    def geo_id_params(options=nil)
      {
        geo_ids: ids.join(' '),
        typology: options[:typology],
        category: options[:category]
      }
    end

  end
end
