class DemandController < TabController
  def intro
    Current.already_shown?('demand', true)
    
    bars  = ['Households']
    bars += ['Buildings'] if Current.setting.area
    bars += ['Transport', 'Industry', 'Agriculture', 'Other']
    
    queries = ['present:SUM(V(G(final_demand_cbs);final_demand))']
    queries += bars.map{|x| "present:SUM(V(INTERSECTION(G(final_demand_cbs),SECTOR(#{x.downcase}));final_demand))"}
    
    gql = Api::Client.new
    # Assigning queries now, to prevent multiple requests
    gql.queries = queries
    gql.api_session_id = Current.setting.api_session_key rescue nil
    
    @total = gql.simple_query('present:SUM(V(G(final_demand_cbs);final_demand))')
    
    @items = {}
    
    bars.each do |b|
      key = b.downcase
      val = gql.simple_query("present:SUM(V(INTERSECTION(G(final_demand_cbs),SECTOR(#{key}));final_demand))")
      @items[key] ||= {
        :name      => b,
        :value     => val,
        :percent   => val / @total * 100,
        :clickable => Current.view.sidebar_items.map(&:key).include?(key),
        :active    => params[:action] = key # can this ever happen?
      }
    end
    
  end
end
