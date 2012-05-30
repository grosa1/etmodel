class @Chart extends Backbone.Model
  defaults:
    'container': 'current_chart'

  initialize : ->
    @series = switch @get('type')
      when 'block' then new BlockChartSeries()
      when 'scatter' then new ScatterChartSeries()
      else new ChartSeries()
    @bind('change:type', @render)
    @render()

  render : =>
    type = @get('type')
    @view = switch (type)
      when 'bezier'                 then new BezierChartView({model : this})
      when 'horizontal_bar'         then new HorizontalBarChartView({model : this})
      when 'horizontal_stacked_bar' then new HorizontalStackedBarChartView({model : this})
      when 'mekko'                  then new MekkoChartView({model : this})
      when 'waterfall'              then new WaterfallChartView({model : this})
      when 'vertical_stacked_bar'   then new VerticalStackedBarChartView({model : this})
      when 'grouped_vertical_bar'   then new GroupedVerticalBarChartView({model : this})
      when 'policy_bar'             then new PolicyBarChartView({model : this})
      when 'line'                   then new LineChartView({model : this})
      when 'block'                  then new BlockChartView({model : this})
      when 'vertical_bar'           then new VerticalBarChartView({model : this})
      when 'html_table'             then new HtmlTableChartView({model : this})
      when 'scatter'                then new ScatterChartView({model : this})
      when 'd3'                     then @d3_view_factory()
      else new HtmlTableChartView({model : this})
    @view.update_title()
    @view

  # D3 charts have their own class. Let's make an instance of the right one
  # D3 is a pseudo-namespace. See d3_chart_view.coffee
  d3_view_factory: =>
    key = @.get 'key'
    if D3[key] && D3[key].View
      new D3[key].View({model: this})
    else
      false

  # @return [ApiResultArray] = [
  #   [[2010,0.4],[2040,0.6]],
  #   [[2010,20.4],2040,210.4]]
  # ]
  results : (exclude_target) ->
    if exclude_target
      series = @non_target_series()
    else
      series = @series.toArray()

    out = _(series).map (serie) -> serie.result()

    # policy goal charts show percentages but the gqueries return values
    # in the [0,1] range. Let's take care of that
    if @get('percentage')
      out = _(out).map (serie) ->
        [
          [ serie[0][0], serie[0][1] * 100 ],
          [ serie[1][0], serie[1][1] * 100 ]
        ]
    out

  colors : ->
    @series.map (serie) -> serie.get('color')

  labels : ->
    @series.map (serie) -> serie.get('label')

  # @return [Float] Only values of the present
  values_present: ->
    exclude_target_series = true
    _.map @results(exclude_target_series), (result) ->  result[0][1]

  # @return [Float] Only values of the future
  values_future : ->
    exclude_target_series = true
    _.map @results(exclude_target_series), (result) -> result[1][1]

  # @return [Float] All possible values. Helpful to determine min/max values
  values : ->
    _.flatten([@values_present(), @values_future()])

  # @return [[Float,Float]] Array of present/future values [Float,Float]
  value_pairs :->
    @series.map (serie) -> serie.result_pairs()

  non_target_series : ->
    @series.reject (serie) -> serie.get('is_target_line')

  target_series : ->
    @series.select (serie) -> serie.get('is_target_line')

  # @return Array of present and future target
  target_results : ->
    _.flatten _.map(@target_series(), (serie) -> serie.future_value())

  # @return Array of hashes {label, present_value, future_value}
  series_hash : ->
    @series.map (serie) ->
      label : serie.get('label')
      present_value : serie.present_value()
      future_value : serie.future_value()

  # This is used to show a chart as a table
  # See base_chart_view#render_as_table
  formatted_series_hash : ->
    items = @non_target_series().map (serie) =>
      label = serie.get 'label'
      label = "#{label} - #{serie.get('group')}" if @get('type') == 'mekko'
      out =
        label: label
        present_value: Metric.autoscale_value(serie.present_value(), @get('unit'), 2)
        future_value: Metric.autoscale_value(serie.future_value(), @get('unit'), 2)
    # some charts draw series bottom to top. Let's flip the array
    return items.reverse() if @get('type') in ['vertical_stacked_bar', 'bezier']
    items

class @ChartList extends Backbone.Collection
  model : Chart

  initialize: ->
    $.jqplot.config.enablePlugins = true
    @setup_callbacks()

  # table and cost charts are HTML-based. Their HTML is returned by the Rails app
  # and the Backbone app takes care of inserting it into the DOM adding
  # the gqueries result values. This hash stores the HTML for the charts
  # using the chart_id as key.
  html: {}

  load : (chart_id) ->
    return false if App.settings.get('pinned_chart')
    App.etm_debug('Loading chart: #' + chart_id)
    App.etm_debug "#{window.location.origin}/admin/output_elements/#{chart_id}"
    url = "/output_elements/#{chart_id}.js"
    $.getScript url, =>
      # show/hide default chart button
      #
      $("a.default_charts").toggle(chart_id != @current_default_chart)

      # show/hide format toggle button
      #
      $("a.table_format").toggle( @current().view.can_be_shown_as_table() )
      $("a.chart_format").hide()

      # update chart information link
      #
      $("#output_element_actions a.chart_info").attr("href", "/descriptions/charts/#{chart_id}")

      # update the position of the output_element_actions
      #
      $("#output_element_actions").removeClass()
      $("#output_element_actions").addClass(@first().get("type"))

      # show.hide the under_construction notice
      #
      $("#chart_not_finished").toggle @first().get("under_construction")
      App.call_api()
      @first()

  # returns the current chart id
  current_id : ->
    parseInt(@first().get('id'))

  current: -> @first()

  setup_callbacks: ->
    $("a.default_charts").live 'click', =>
      App.settings.set({pinned_chart: false})
      $("a.pin_chart").removeClass("active")
      @load(@current_default_chart)
      false

    $("a.pick_charts").live 'click', (e) =>
      App.settings.set({pinned_chart: false})
      $("a.pin_chart").removeClass("active")
      chart_id = $(e.target).parents('a').data('chart_id')
      @load chart_id
      close_fancybox()

    $("a.table_format").live 'click', =>
      $("a.table_format").hide()
      $("a.chart_format").show()
      @current().view.toggle_format()
      false

    $("a.chart_format").live 'click', =>
      $("a.chart_format").hide()
      $("a.table_format").show()
      @current().view.toggle_format()
      false

    $(document).on 'click', "a.pin_chart", (e) =>
      e.preventDefault()
      $(e.target).parents("a").toggleClass("active")
      if App.settings.get('pinned_chart')
        App.settings.set({pinned_chart: false})
      else
        App.settings.set({pinned_chart: @current_id()})

    # This callback tries throttling the resize event, which is fired
    # continuously while the user resizes the window. Once the resize is over
    # the chart will be rendered again
    resize_callback = null
    $(window).on 'resize', =>
      clearTimeout(resize_callback)
      resize_callback = setTimeout(@current().view.render, 100)

window.charts = new ChartList()
