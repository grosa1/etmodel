# == Schema Information
#
# Table name: predictions
#
#  id               :integer(4)      not null, primary key
#  input_element_id :integer(4)
#  user_id          :integer(4)
#  expert           :boolean(1)
#  curve_type       :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  description      :text
#  title            :string(255)
#  area             :string(255)
#

class Prediction < ActiveRecord::Base
  belongs_to :user
  belongs_to :input_element
  has_many :values,   :class_name => "PredictionValue",   :dependent => :destroy
  has_many :measures, :class_name => "PredictionMeasure", :dependent => :destroy
    
  has_paper_trail
  acts_as_commentable
  
  accepts_nested_attributes_for :values,   :allow_destroy => true, :reject_if => proc {|a| a[:year].blank? || a[:value].blank? }
  accepts_nested_attributes_for :measures, :allow_destroy => true, :reject_if => proc {|a| a[:name].blank? }
  
  validates :title, :presence => true
  validates :input_element_id, :presence => true
  
  scope :for_area, lambda{|a| where(:area => a)}
  
  def last_value
    @last_value ||= values.future_first.first
  end
  
  # Prepare blank records, useful when building forms
  def prepare_nested_attributes
    (8 - values.size).times { values.build }
    (8 - measures.size).times { measures.build }
  end
  
  # Prepare blank records, useful when building forms
  def add_blank_nested_attributes
    8.times { values.build }
    8.times { measures.build }
  end
  
  def values_to_a
    values.map{|v| [v.year, v.value]}
  end
  
  def values_to_h
    @values_hash ||= {}.tap{|h| values.each{|v| h[v.year] = v.value}}
  end
  
  def max_value
    values.map(&:value).compact.max
  end
  
  def min_value
    values.map(&:value).compact.min
  end
  
  # calculates the prediction value for a year
  def value_for_year(x)
    hash = values_to_h
    # empty prediction
    return nil if hash.empty?
    # exact value
    return hash[x] if hash[x]
    # single value
    return hash.values.first if hash.size == 1
    # year outside the range. We could also use linear extrapolation
    years = hash.keys.sort
    if x > (max_year = years.max)
      return hash[max_year]
    end
    if x < (min_year = years.min)
      return hash[min_year]
    end
    # linear interpolation    
    x0 = years.select{|z| z < x}.max
    x1 = years.select{|z| z > x}.min
    y0 = hash[x0]
    y1 = hash[x1]
    y = y0 + (x - x0) * ((y1- y0) / (x1 - x0))
  end
  
  # The slider often uses a different unit from the prediction. Let's convert it
  def corresponding_slider_value
    raw = value_for_year(Current.setting.end_year)
    case input_element.command_type
      when 'value'
        raw
      when 'growth_rate'
        # This assumes the prediction values use 100 as current value
        # while the slider assumes 0 as current value
        raw - 100
      when 'efficiency_improvement'
        false
      else
        false
    end
  rescue
    false
  end
end
