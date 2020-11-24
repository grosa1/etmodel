D3.merit_order_hourly_supply =
  View: class extends D3YearlyChartView
    initialize: ->
      D3YearlyChartView.prototype.initialize.call(this)

    dataForChart: ->
      @series = @getSeries().concat(@model.target_series())
      @series.map(@getSerie)

    filterYValue: (value) ->
      if value > 0 then value else 0

    draw: ->
      super

      @drawLegend(@getLegendSeries())

      defs = @svg.append('defs')
      defs.append('clipPath')
          .attr('id', "clip_" + @chart_container_id())
          .append('rect')
          .attr('width', @width)
          .attr('height', @height)

    getLegendSeries: ->
      # Filter series whose values are all zero.
      @series.filter (serie) -> _.some(serie.future_value())

    getSeries: ->
      transformOpts =
        this.dateSelect && this.dateSelect.toTransformOptions() ||
          { downsampleMethod: this.downsampleWith }

      _.sortBy @model.non_target_series(), (serie) =>
        values = MeritTransformator.transform(
          serie.future_value(),
          transformOpts
        )

        min = max = sum = 0

        for value in values
          if value < min then min = value
          if value > max then max = value
          sum += value

        return 0 if sum == 0

        Math.abs((max - min) / sum)

    drawData: (xScale, yScale, area, line) ->
      @svg.selectAll('path.serie')
        .data(@stackedData)
        .enter()
        .append('g')
        .attr('id', (data, index) -> "path_#{ index }")
        .attr('clip-path', "url(#clip_" + @chart_container_id() + ")")
        .attr("class", "serie")
        .append('path')
        .attr('class', (data) -> "area " + data.key)
        .attr('d', (data) -> area(data.values) )
        .attr('fill', (data) -> data.color )
        .attr('data-tooltip-text', (d) -> d.label)

      $("#{@container_selector()} path.area").qtip
        content:
          text:  -> $(this).attr('data-tooltip-text')
        position:
          target: 'mouse'
          my: 'bottom right'
          at: 'top center'

      @svg.selectAll('path.serie')
        .data(@totalDemand)
        .enter()
        .append('g')
        .attr('id', (data, index) -> "path_#{ index }")
        .attr('clip-path', "url(#clip_" + @chart_container_id() + ")")
        .attr("class", "serie-line")
        .append('path')
        .attr('class', 'line')
        .attr('d', (data) -> line(data.values) )
        .attr('stroke', (data) -> data.color )
        .attr('stroke-width', 2)
        .attr('fill', 'none')

    refresh: (xScale, yScale) ->
      super

      @setStackedData()
      @drawLegend(@getLegendSeries())

      xScale = @createTimeScale(@dateSelect.currentRange())
      yScale = @createLinearScale()
      area   = @area(xScale, yScale)
      line   = @line(xScale, yScale)

      @svg.select(".x_axis").call(@createTimeAxis(xScale))
      @svg.select(".y_axis").call(@createLinearAxis(yScale))

      if @container_node().find("g.serie").length > 0
        @svg.selectAll('g.serie')
          .data(@stackedData)
          .select('path.area')
          .attr('d', (data) -> area(data.values) )
          .attr('fill', (data) -> data.color )
          .attr('data-tooltip-text', (d) -> d.label)

        @svg.selectAll('g.serie-line')
          .data(@totalDemand)
          .select('path.line')
          .attr('d', (data) -> line(data.values) )

      else
        @drawData(xScale, yScale, area, line)

    area: (xScale, yScale) ->
      d3.svg.area()
        .x((data) -> xScale(data.x))
        .y0((data) -> yScale(data.y0))
        .y1((data) -> yScale(data.y0 + data.y))
        .interpolate('monotone')

    line: (xScale, yScale) ->
      d3.svg.line()
        .x((data) -> xScale(data.x))
        .y((data) -> yScale(data.y))
        .interpolate('monotone')
