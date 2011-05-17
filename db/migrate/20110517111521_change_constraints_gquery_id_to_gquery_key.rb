class ChangeConstraintsGqueryIdToGqueryKey < ActiveRecord::Migration
  def self.up
    add_column :constraints, :gquery_key, :string

    Constraint.find(1).update_attribute :gquery_key, 'policy_total_primary_energy'
    Constraint.find(2).update_attribute :gquery_key, 'policy_co2_reduction'
    Constraint.find(3).update_attribute :gquery_key, 'policy_net_energy_import'
    Constraint.find(4).update_attribute :gquery_key, 'policy_total_energy_cost'
    Constraint.find(5).update_attribute :gquery_key, 'policy_not_shown'
    Constraint.find(6).update_attribute :gquery_key, 'policy_renewable_percentage'
    Constraint.find(7).update_attribute :gquery_key, 'policy_targets_met'
    Constraint.find(8).update_attribute :gquery_key, 'policy_score'

    remove_column :constraints, :gquery_id
  end

  def self.down
    add_column :constraints, :gquery_id, :integer
    remove_column :constraints, :gquery_key
  end
end
