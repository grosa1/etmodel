class Node
  constructor: (attrs) ->
    @x = attrs.x
    @y = attrs.y
    @key = attrs.key

class Link
  constructor: (left, right) ->
    @left = left
    @right = right

  path_points: =>
    [
      {x: @left.x + 70,  y: @left.y + 25},
      {x: @left.x + 270,  y: @left.y + 25},
      {x: @right.x - 200, y: @right.y + 25}
      {x: @right.x, y: @right.y + 25}
    ]

class Topology
  constructor: ->
    @width = 800
    @height = 500
    d3.json 'http://etengine.dev/api/v3/converters/topology', @render

  render: (data) =>
    return if @rendered

    @nodes = []
    @nodes_map = {}
    for d in data.converters
      i = new Node(d)
      @nodes.push i
      @nodes_map[i.key] = i

    @links = []
    for l in data.links
      left = @nodes_map[l.left]
      right = @nodes_map[l.right]
      @links.push new Link(left, right)

    @svg = d3.select('#topology')
      .append('svg')
      .attr('width', @width)
      .attr('height', @height)
      .attr("pointer-events", "all")
      .call(d3.behavior.zoom().on("zoom", @rescale))
      .append('g')

    max_x = d3.max(@nodes, (d) -> d.x) + 50
    max_y = d3.max(@nodes, (d) -> d.y) + 50
    @x = d3.scale.linear().domain([0, max_x]).range([0, @width])
    @y = d3.scale.linear().domain([0, max_y]).range([0, @height])

    @colors = d3.scale.category20c()

    @nodes = @svg.selectAll('g.node')
      .data(@nodes, (d) -> d.key)
      .enter()
      .append('g')
      .attr('class', 'node')
      .attr('transform', (d) => "translate(#{@x d.x},#{@y d.y})")

    @nodes.append('svg:rect')
      .attr('width', @x 70)
      .attr('height', @y 50)
      .attr('fill', (d, i) => @colors i)
      .attr('data-tooltip', (d) -> d.key)

    @make_line = d3.svg.line()
        .interpolate("basis")
        .x((d) -> @x d.x)
        .y((d) -> @y d.y)

    @links = @svg.selectAll('path.link')
      .data(@links)
      .enter()
      .append('path')
      .attr('class', 'link')
      .style('stroke-width', 0.2)
      .style('stroke', '#000000')
      .style("fill", "none")
      .attr('d', (link) => @make_line link.path_points())

    @rendered = true

    $('rect').qtip
      content: -> $(this).attr('data-tooltip')
      position:
        my: 'bottom left'
        at: 'top center'
      style:
        classes: "ui-tooltip-tipsy"

  rescale: =>
    console.log "Rescaling"
    trans = d3.event.translate
    scale = d3.event.scale
    @svg.attr("transform", "translate(#{trans}) scale(#{scale})")

$ ->
  window.chart = new Topology()