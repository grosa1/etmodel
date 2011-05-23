##
# Class for all user settings that should persist over a session.
#
class Setting
  
  DEFAULT_ATTRIBUTES = {
    :show_municipality_introduction => true,
    :hide_unadaptable_sliders => false,
    :network_parts_affected => [],
    :track_peak_load => true,
    :complexity => 3,
    :country => 'nl',
    :region => nil,
    :start_year => 2010,
    :end_year => 2040
  }

  attr_accessor *DEFAULT_ATTRIBUTES.keys

  attr_accessor :last_etm_controller_name,
                :last_etm_controller_action,
                :displayed_output_element,
                :selected_output_element
                

  ##
  # @tested 2010-12-06 seb
  #
  def initialize(attributes = {}) 
    attributes = self.class.default_attributes.merge(attributes)
    attributes.each do |name, value|  
      send("#{name}=", value)  
    end
  end

  def [](key)
    self.send("#{key}")
  end

  def []=(key, param)
    self.send("#{key}=", param)
  end

  ##
  # @tested 2010-12-07 seb
  #
  def track_peak_load?
    use_peak_load and track_peak_load
  end
  
  ##
  # @tested 2010-12-06 seb
  #
  def self.default
    new(default_attributes)
  end

  ##
  # @tested 2010-12-06 seb
  #
  def self.default_attributes
    DEFAULT_ATTRIBUTES
  end


  ##
  # @tested 2010-12-06 seb
  #
  def reset!
    self.class.default_attributes.each do |key, value|
      send("#{key}=", value)
    end
  end
  ####### Complexities

  LEVELS = {
    1 => 'simple',
    2 => 'medium',
    3 => 'advanced',
    4 => 'municipalities',
    5 => 'watt_nu',
    6 => 'new_municipality_view',
    7 => 'ameland_advanced',
    8 => 'network'
  }


  ##
  # @untested 2011-01-24 robbert
  # 
  def all_levels
    LEVELS
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def complexity=(param)
    @complexity = param.andand.to_i
  end


  ##
  # @untested 2011-01-09 seb
  # 
  def complexity_key
    LEVELS[self.complexity.to_i]
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def simple?;    self.complexity == 1; end
  def medium?;    self.complexity == 2; end
  def advanced?;  self.complexity == 3; end

  ####### Years

  def end_year=(end_year)
    @end_year = end_year.to_i
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def years
    end_year - start_year
  end

  ####### Peak load

  ##
  # @tested 2010-11-30 seb
  # 
  def use_peak_load
    Current.setting.advanced? and Current.setting.use_network_calculations?
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def use_network_calculations?
    area.andand.use_network_calculations == true
  end


  ####### Area / Region

  attr_writer :area


  ##
  # @tested 2010-11-30 seb
  # 
  def set_country_and_region(country, region)
    self.country = country
    self.region = if region.blank? then nil
      elsif region.is_a?(Hash) 
        if region.has_key?(country) 
          region[country]  # You may want to set the province here and override country settings (maybe add a country prefix?)
        else 
          nil
        end
      else region
    end
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def municipality?
    area.andand.is_municipality? == true
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def has_buildings?
    area.andand.has_buildings == true
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def region_or_country
    region || country
  end

  ##
  # @tested 2010-12-06 seb
  # 
  def area_region
    Area.find_by_country(region)
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def area
    @area ||= Area.find_by_country(region_or_country)
  end


  ##
  # @tested 2010-11-30 seb
  # 
  def number_of_households
    self[:number_of_households] ||= area.andand.number_households
  end

  def number_of_households=(value)
    self[:number_of_households] = value
  end


  ##
  # @tested 2010-11-30 seb
  # 
  def number_of_existing_households
    self[:number_of_existing_households] ||= area.andand.number_of_existing_households
  end

  def number_of_existing_households=(value)
    self[:number_of_existing_households] = value
  end


  def score_to_tracker
    scores = Current.gql.policy.goals.map{|g| [g.name,g.score.to_s]}
    
    number_of_rounds = Round.where('completed = 1').length
    
    array_to_send = scores.take(number_of_rounds) 
    
    (scores.length - number_of_rounds).times do
    
      array_to_send << ["x", "x"]
    end
    array_to_send << ["Total", array_to_send.collect{|x| x.last.to_i}.sum]
    
    array_to_send
  end

  ##
  # Is it this or that type of scenario?
  # 
  # @param [String, Symbol] type
  # @return [Boolean]
  #
  # @untested 2010-12-21 jape
  #
  def is_scenario_type?(type)
    self.scenario_type && self.scenario_type == type.to_s
  end
  
  def current_view
    Current.setting.all_levels[complexity.to_i]
  end
  
end