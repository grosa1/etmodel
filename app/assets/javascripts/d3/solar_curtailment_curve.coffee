D3.solar_curtailment_curve =
  View: class extends D3.dynamic_demand_curve.View


    draw: ->
      super

      @serieSelect = new D3ChartSerieSelect(@container_selector(),
                                            @serieSelectOptions())
      @serieSelect.draw(@refresh.bind(this))

    visibleData: ->
      val = @serieSelect?.selectBox.val() || @serieSelectOptions()[0]
      super().filter((serie) -> serie.key.includes(val))

    getLegendSeries: ->
      legendSeries = []
      val = @serieSelect.selectBox.val()
      @series.forEach (serie) =>
         if serie.attributes.gquery_key.includes(val)
           legendSeries.push(serie)

      legendSeries

    serieSelectOptions: ->
      return ['solar_pv',
             'buildings_solar_pv',
             'households_solar_pv',
             'energy_power_solar_pv']


# TODO
# generate options instead of putting them in hard
# tooltips
# link the table view

