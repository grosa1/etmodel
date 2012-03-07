/* DO NOT MODIFY. This file was compiled Wed, 07 Mar 2012 11:01:42 GMT from
 * /Users/paozac/Sites/etmodel/app/coffeescripts/lib/views/base_chart_view.coffee
 */

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  this.BaseChartView = (function(_super) {

    __extends(BaseChartView, _super);

    function BaseChartView() {
      this.render_as_table = __bind(this.render_as_table, this);
      BaseChartView.__super__.constructor.apply(this, arguments);
    }

    BaseChartView.prototype.initialize_defaults = function() {
      return this.model.bind('change', this.render);
    };

    BaseChartView.prototype.clear_container = function() {
      return this.container_node().empty();
    };

    BaseChartView.prototype.max_value = function() {
      var max_value, sum_future, sum_present, target_results;
      sum_present = _.reduce(this.model.values_present(), function(sum, v) {
        var _ref;
        return sum + ((_ref = v > 0) != null ? _ref : {
          v: 0
        });
      });
      sum_future = _.reduce(this.model.values_future(), function(sum, v) {
        var _ref;
        return sum + ((_ref = v > 0) != null ? _ref : {
          v: 0
        });
      });
      target_results = _.flatten(this.model.target_results());
      return max_value = _.max($.merge([sum_present, sum_future], target_results));
    };

    BaseChartView.prototype.parsed_unit = function() {
      var unit;
      unit = this.model.get('unit');
      return Metric.scale_unit(this.max_value(), unit);
    };

    BaseChartView.prototype.data_scale = function() {
      return Metric.power_of_thousand(this.max_value());
    };

    BaseChartView.prototype.container_id = function() {
      return this.model.get("container");
    };

    BaseChartView.prototype.container_node = function() {
      return $("#" + (this.container_id()));
    };

    BaseChartView.prototype.title_node = function() {
      return $("#charts_holder h3");
    };

    BaseChartView.prototype.update_title = function() {
      return this.title_node().html(this.model.get("name"));
    };

    BaseChartView.prototype.create_legend = function(opts) {
      return {
        renderer: $.jqplot.EnhancedLegendRenderer,
        show: true,
        location: opts.location || 's',
        fontSize: this.defaults.font_size,
        placement: "outside",
        labels: opts.labels || this.model.labels(),
        yoffset: opts.offset || 25,
        rendererOptions: {
          numberColumns: opts.num_columns,
          seriesToggle: false
        }
      };
    };

    BaseChartView.prototype.defaults = {
      shadow: false,
      font_size: '11px',
      grid: {
        drawGridLines: false,
        gridLineColor: '#cccccc',
        background: '#ffffff',
        borderColor: '#cccccc',
        borderWidth: 0.0,
        shadow: false
      },
      stacked_line_axis_default: {
        tickOptions: {
          formatString: '%d',
          fontSize: '11px'
        }
      }
    };

    BaseChartView.prototype.toggle_format = function() {
      this.display_as_table = !this.display_as_table;
      console.log(this.display_as_table);
      if (this.can_be_shown_as_table() && this.display_as_table) {
        return this.render_as_table();
      } else {
        return this.render();
      }
    };

    BaseChartView.prototype.can_be_shown_as_table = function() {
      return true;
    };

    BaseChartView.prototype.render_as_table = function() {
      var table, table_data, tmpl;
      console.log("Hi! I'm a table");
      this.clear_container();
      table_data = {
        start_year: App.settings.get('start_year'),
        end_year: App.settings.get('end_year'),
        series: this.model.series_hash()
      };
      tmpl = $("#chart-table-template").html();
      table = _.template(tmpl, table_data);
      return this.container_node().html(table);
    };

    return BaseChartView;

  })(Backbone.View);

}).call(this);
