{div,span,select,option,table,thead,tbody,tr,td,th,h3,hr,label} = React.DOM


PuzApp = React.createClass {
  parseW13report: (files)->
    ExcelParser.parse(files[0], (excel)=>
      @setState(
        w13doc: W13Builder.build excel
        product: null
        isModels: excel.name.toLowerCase().indexOf('models') != -1
        selectedWeek: 0
      ))

  parsePOreport: (files)->
    ExcelParser.parse(files[0], (excel)=>
      variable = POBuilder.build excel
      @setState(
        podoc: variable
      ))

  changeWeek: (week)->
    @setState(
      selectedWeek: week
    )

  getInitialState: ->
    w13doc: null
    podoc: null
    isModels: false
    selectedWeek: -1

  render: ->
    dropZones = [
      div
        className: 'col-md-' + if @state.isModels or not @state.w13doc then '12' else '6',
        DropZone {
          text: 'w13.xls or w13models.xls'
          onDropFile: @parseW13report
          className: if @state.w13doc then 'loaded' else 'empty'
        }
    ]

    if @state.w13doc and not @state.isModels
      dropZones.push div
        className: 'col-md-6',
        DropZone {
          text: 'PO.xls'
          onDropFile: @parsePOreport
          className: 'loaded' if @state.podoc
        }

    components = [
      div
        className: 'row',
        dropZones
    ]

    if @state.w13doc?
      components.push div
        className: 'row',
        div
          className: 'col-md-12',
          [
            hr {}, ''
            h3 {}, 'Look for materials:'
          ]
      ,
        div
          className: 'row',
          div
            className: 'col-md-12',
            div
              className: 'form',
              div
                className: 'form-group',
                [
                  label {}, 'Week'
                  WeeksList {
                    weeks: @state.w13doc?.weeks
                    value: @state.selectedWeek
                    onChange: @changeWeek
                  }
                ]
      list = if @state.isModels
        MaterialModelsList {
          selectedWeek: @state.selectedWeek
          w13doc: @state.w13doc
        }
      else
        MaterialList {
          selectedWeek: @state.selectedWeek
          w13doc: @state.w13doc
          podoc: @state.podoc
        }

      components.push div
        className: 'row',
        div
          className: 'col-md-12',
          list

    div {}, components
}


DropZone = React.createClass {
  onDragOver: (e)->
    e.stopPropagation()
    e.preventDefault()
    e.dataTransfer.dropEffect = 'copy'
    @getDOMNode().classList.add 'over'

  onDragLeave: ->
    @getDOMNode().classList.remove 'over'

  onDrop: (e)->
    e.stopPropagation()
    e.preventDefault()
    @getDOMNode().classList.remove 'over'
    files = e.dataTransfer.files
    @props.onDropFile files

  render: ->
    div
      className: 'drop_zone ' + (@props.className ? '')
      onDragOver: @onDragOver
      onDragLeave: @onDragLeave
      onDrop: @onDrop
    , span {}, @props.text
}


WeeksList = React.createClass {
  onChange: ->
    @props.onChange parseInt(@getDOMNode().value)

  render: ->
    options = (option({value: indx}, week) for week,indx in @props.weeks ? [])
    select
      className: 'form-control'
      value: @props.value
      onChange: @onChange,
      options
}


MaterialList = React.createClass {
  getInitialState: ->
    selectedVendor: 'All'

  componentWillReceiveProps: ->
    @setState(selectedVendor: 'All')

  selectVendor: (vendor)->
    @setState(selectedVendor: vendor)

  render: ->
    shortMaterials = (material for material in @props.w13doc?.materials ? [] when material.balanceSN[@props.selectedWeek] < 0)
    vendors = []
    vendors.push vendorName for vendorName in material.vendors when vendors.indexOf(vendorName) == -1 for material in shortMaterials

    filtered = shortMaterials
    if @state.selectedVendor isnt 'All'
      filtered = shortMaterials.filter (r)=>
        r.vendors.indexOf(@state.selectedVendor) isnt -1

    poHeadVendors = []
    rowsTds = for material in filtered
      cells = [
        td {}, material.name
        td {}, material.vendors.join(', ')
        td {}, material.purOrder
        td {className: 'negative'}, material.balanceSN[@props.selectedWeek]
        td {}, material.balanceSN[@props.selectedWeek + 1] ? ''
        td {}, material.balanceSN[@props.selectedWeek + 2] ? ''
      ]

      if @props.podoc
        poMaterial = @props.podoc.materials[material.name]
        qty = if poMaterial then (poVendor.qty for povName,poVendor of poMaterial.vendors).reduce (v1, v2)-> v1 + v2 else ''
        if poMaterial
          poHeadVendors.push povName for povName of poMaterial.vendors when poHeadVendors.indexOf(povName) is -1
        cells.push td {}, qty
        cells.push td {}, (if poMaterial then poMaterial.vendors[pohvName]?.qty else '') for pohvName in poHeadVendors

      cells

    rows = for cells in rowsTds
      maxCellsLength = rowsTds[rowsTds.length - 1].length
      while cells.length < maxCellsLength
        cells.push td {}, ''
      tr {}, cells

    heads = [
      th {}, 'Material'
      th {}, VendorsList
        vendors: vendors
        value: @state.selectedVendor
        onChange: @selectVendor
      th {}, 'Pur. Order'
      th {className: 'negative'}, @props.w13doc?.weeks[@props.selectedWeek]
      th {}, @props.w13doc?.weeks[@props.selectedWeek + 1] ? ''
      th {}, @props.w13doc?.weeks[@props.selectedWeek + 2] ? ''
    ]

    if @props.podoc?
      heads.push th {}, 'Total'
      heads.push th {}, poVendorName for poVendorName in poHeadVendors

    table
      className: 'table table-striped table-hover',
      [
        thead {},
          tr {}, heads
        tbody {}, rows
      ]
}


VendorsList = React.createClass {
  onChange: ->
    @props.onChange @getDOMNode().value.trim()

  render: ->
    options = (option({value: vendor}, vendor) for vendor in @props.vendors)
    options.unshift(option({}, 'All'))
    select
      className: 'form-control'
      value: @props.value
      onChange: @onChange,
      options

}


MaterialModelsList = React.createClass {
  render: ->
    rows = for material in @props.doc.materials when material.balanceSN[@props.selectedWeek] < 0
      short = material.balanceSN[@props.selectedWeek]

      productForReduce = (name: product.name, qty: product.qty[@props.selectedWeek] for product in material.blocked when product.qty[@props.selectedWeek] > 0)
      productForReduce.sort (p1, p2)-> p2.qty - p1.qty

      productsRows = for product in productForReduce when short < 0
        qtyCanMade = product.qty + short
        if qtyCanMade < 0
          short = qtyCanMade
          qtyCanMade = 0
        else
          short = 0
        tr {}, [
          td {}, ''
          td {}, product.name
          td {}, product.qty
          td {}, qtyCanMade
          td {}, ''
        ]
      productsRows.unshift tr {className: 'negative' if short < 0}, [
        td {}, material.name
        td {}, ''
        td {}, ''
        td {}, short
        td {className: 'negative'}, material.balanceSN[@props.selectedWeek]
      ]
      productsRows

    table
      className: 'table table-striped table-hover',
      [
        thead {},
          tr {}, [
            th {}, 'Material'
            th {}, 'Product'
            th {}, 'Forecast'
            th {}, 'Result'
            th {className: 'negative'}, @props.doc?.weeks[@props.selectedWeek]
          ]
        tbody {}, rows
      ]
}