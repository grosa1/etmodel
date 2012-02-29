
var VerticalStackedBarChartView = BaseChartView.extend({
  initialize : function() {
    this.initialize_defaults();
  },

  render : function() {
    this.clear_container();
    InitializeVerticalStackedBar(this.model.get("container"), 
      this.results(), 
      this.ticks(),
      this.filler(),
      this.model.get('show_point_label'),
      this.parsed_unit(),
      this.model.colors(),
      this.model.labels());
  },

  results : function() {
    var results = this.results_without_targets();
    var smallest_scale = null; 

    if (!this.model.get('percentage')) {
      var smallest_value = _.min(this.model.values());
      smallest_scale = Metric.scaled_scale(smallest_value, 3);

      results = _.map(results, function(x) {
        return _.map(x, function(value) {
          // DEBT DEBT DEBT UGLY UGLY UGLY rewrite Metric.js!!!
          if (value < 1 && smallest_scale === 0) return value;
          return Metric.scaled_value(value, 3, smallest_scale);
        });
      });
    }

    _.each(this.model.target_series(), function(serie) {
      var result = serie.result()[0][1]; // target_series has only present or future value
      if (smallest_scale)
        result = Metric.scaled_value(result, 3, smallest_scale);
      var x = parseFloat(serie.get('target_line_position'));
      results.push([[x - 0.4, result], [x + 0.4, result]]);
    });
    return results;
  },

  results_without_targets : function() {
    return _.map(this.model.non_target_series(), function(serie) { return serie.result_pairs(); });
  },
  filler : function() {
    return _.map(this.model.non_target_series(), function(serie) { return {}; });
  },
  ticks : function() {
    return [App.settings.get("start_year"), App.settings.get("end_year")];
  }
});
