module Splendia
  class SearchHotel < Splendia::Search

    attr_reader :ids, :responses

    DEFAULT_SLICE = 150

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

    def search(options={})
      params = search_params.merge(hotel_params)
      create_list_response Splendia::Client.hotels(params)
    end


    def page_hotels(options={}, &block)
      responses, slice_by = [],  (options[:slice] || DEFAULT_SLICE)

      time = Benchmark.realtime do 
        (conn = Splendia::Client.http).in_parallel do 
          ids.each_slice(slice_by) do |sliced_ids|          
            Log.info "Sending request of #{sliced_ids.count} hotels to Splendia:\n"
            params = search_params.merge(hotel_params(sliced_ids))
            responses << conn.get( Splendia::Client.url, params)
          end
        end
      end

      hotels = collect_hotels(concat_responses(responses))
      Log.info "Collected #{hotels.count} hotels out of #{responses.count} Splendia responses for comparison in #{time}s"
      yield hotels if block_given?
    end 

    def concat_responses(responses)
      responses.map {|response| create_list_response Nokogiri.XML(response.body)}
    end

    def collect_hotels(list_responses)
      list_responses.flat_map {|list_response| list_response.hotels}
    end

    def hotel_params(custom_ids=nil)
      {
        hotels: (custom_ids || ids).join(',')
      }
    end

  end
end