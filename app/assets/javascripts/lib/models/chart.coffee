class @Chart extends Backbone.Model
  defaults:
    'container': 'main_chart'

  initialize : ->
    # every chart has a series (=~ gqueries) collection. This helps us handling
    # them
    @series = switch @get('type')
      when 'block' then new BlockChartSeries()
      when 'scatter' then new ScatterChartSeries()
      else new ChartSeries()
    @bind('change:type', @render)
    @render()

  render : =>
    type = @get('type')
    view_class = switch type
      when 'bezier'                 then BezierChartView
      when 'horizontal_bar'         then HorizontalBarChartView
      when 'horizontal_stacked_bar' then HorizontalStackedBarChartView
      when 'mekko'                  then MekkoChartView
      when 'waterfall'              then WaterfallChartView
      when 'vertical_stacked_bar'   then VerticalStackedBarChartView
      when 'grouped_vertical_bar'   then GroupedVerticalBarChartView
      when 'policy_bar'             then PolicyBarChartView
      when 'line'                   then LineChartView
      when 'block'                  then BlockChartView
      when 'vertical_bar'           then VerticalBarChartView
      when 'html_table'             then HtmlTableChartView
      when 'scatter'                then ScatterChartView
      when 'd3'                     then @d3_view_factory()
      else HtmlTableChartView
    @view = new view_class
      model: this
      el: @outer_container()
    @view.update_title()
    @view

  # the container just holds the chart, the outer container has the chart
  # action links, title, etc.
  outer_container: => $('#' + @get('container')).parents(".chart_holder")

  # D3 charts have their own class. Let's make an instance of the right one
  # D3 is a pseudo-namespace. See d3_chart_view.coffee
  d3_view_factory: =>
    key = @.get 'key'
    if D3[key] && D3[key].View
      D3[key].View
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
    # the @non_target_series() array is wrapped in underscore to fix an IE8 bug
    items = _(@non_target_series()).map (serie) =>
      label = serie.get 'label'
      label = "#{label} - #{serie.get('group')}" if @get('type') == 'mekko'
      out =
        label: label
        present_value: Metric.autoscale_value(serie.present_value(), @get('unit'), 2)
        future_value: Metric.autoscale_value(serie.future_value(), @get('unit'), 2)
    # some charts draw series bottom to top. Let's flip the array
    return items.reverse() if @get('type') in ['vertical_stacked_bar', 'bezier']
    items

  # raw array of the associated gqueries. Delegates to the collection object
  #
  gqueries: => @series.gqueries()

  # let's get rid of the gqueries we don't need anymore. This is called when we
  # remove a chart and don't want stale gqueries lying around.
  #
  delete_gqueries: =>
    g.release() for g in @gqueries()
    gqueries.cleanup()

  supported_by_current_browser: =>
    if @get('type') == 'd3' && !Browser.hasD3Support()
      false
    else
      true

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

  # We can have multiple charts. This hash keeps track ok which chart holders
  # are being used
  chart_holders: {}

  # Loads a chart. Parameters:
  # - container_id: id of the dom element that will hold the chart
  # - options: hash with these keys:
  #  - wait: if true an api_call won't be fired immediately. Useful when we want
  #    to show multiple charts on the same page
  #  - alternate: id of the chart to load if the first one fails. Watch out for
  #    loops!
  load : (chart_id, container_id = 'main_chart', options = {}) ->
    wait = options.wait || false
    alternate = options.alternate || false
    return false if App.settings.get(container_id) # chart is pinned

    App.etm_debug('Loading chart: #' + chart_id)
    App.etm_debug "#{window.location.origin}/admin/output_elements/#{chart_id}"
    url = "/output_elements/#{chart_id}"
    $.ajax
      url: url
      success: (data) =>
        # store the chart HTML (tables and block chart)
        @html[chart_id] = data.html
        # Add to the Chart constructor options the id of the container element
        data.attributes.container = container_id
        # Remember what we were showing in that position
        old_chart = @chart_holders[container_id]
        # Create the new Chart
        new_chart = new Chart(data.attributes)
        if !new_chart.supported_by_current_browser()
          if alternate
            @load alternate, container_id
          else
            alert "Sorry! This chart type is not supported by your browser :("
          return false

        # Remember where the chart is
        @chart_holders[container_id] = new_chart
        # Deal with the collection object
        old_chart.delete_gqueries() if old_chart
        @remove old_chart
        @add new_chart
        # Pass the gqueries to the chart
        for s in data.series
          s.owner = container_id
          new_chart.series.add(s)

        # Now it's time to upate the buttons and links for the chart
        root = $('#' + container_id).parents('.chart_holder')
        # show/hide default chart button
        root.find("a.default_charts").toggle(chart_id != @current_default_chart)
        # show/hide format toggle button
        root.find("a.table_format").toggle( new_chart.view.can_be_shown_as_table() )
        root.find("a.chart_format").hide()
        # update chart information link
        root.find(".actions a.chart_info").attr(
          "href", "/descriptions/charts/#{chart_id}")
        # show.hide the under_construction notice
        root.find(".chart_not_finished").toggle new_chart.get("under_construction")
        App.call_api() unless wait
    @last()

  # returns the current chart id
  current_id : => @current().get('id') if @current()

  # returns the main chart
  current: -> @chart_holders['main_chart']

  remove_pin: (holder_id) =>
    App.settings.set holder_id, false
    holder = $('#' + holder_id).parents('.chart_holder')
    holder.find("a.pin_chart").removeClass("icon-lock").addClass("icon-unlock")

  # The default is defined for the main chart only
  load_default: =>
    @remove_pin 'main_chart'
    @load(@current_default_chart, 'main_chart')

  # TODO: Most of this stuff should be moved to a backbone view
  #
  setup_callbacks: ->
    # chart selection pop-up
    $(document).on "click", "a.pick_charts", (e) =>
      chart_holder = $(e.target).parents('a').data('chart_holder')
      chart_id = $(e.target).parents('a').data('chart_id')
      @remove_pin(chart_holder)
      @load chart_id, chart_holder
      close_fancybox()

    $(document).on 'click', "a.pin_chart", (e) =>
      e.preventDefault()
      # which chart are we talking about?
      holder_id = $(e.target).parents(".chart_holder").data('holder_id')
      chart_id = @chart_holders[holder_id].get('id')

      if current = App.settings.get(holder_id)
        value = false
      else
        value = chart_id
      App.settings.set(holder_id, value)
      $(e.target).toggleClass("icon-lock", !!value)
      $(e.target).toggleClass("icon-unlock", !!!value)

    # link to open the secondary chart
    # The busybox setup will open the chart selection popup (see fancybox.coffee)
    $(document).on 'click', 'a.add_secondary_chart', (e) =>
      e.preventDefault()
      # Just show the chart holder
      $(".chart_holder.hidden").removeClass('.hidden').show()
      $(e.target).tipsy("hide")
      $(e.target).remove()

    # This callback tries throttling the resize event, which is fired
    # continuously while the user resizes the window. Once the resize is over
    # the chart will be rendered again
    resize_callback = null
    $(window).on 'resize', =>
      clearTimeout(resize_callback)
      resize_callback = setTimeout(@chart_resize, 100)

  chart_resize: =>
    # the true parameter is used by D3 charts only, jqPlot ignores it
    chart = @current().view.render(true) if @current()

window.charts = new ChartList()
