{div,span,select,option,table,thead,tbody,tr,td,th,h3,hr,label} = React.DOM


PuzApp = React.createClass {
  parseW13report: (files)->
    ExcelParser.parse(files[0], (excel)=>
      doc = W13Builder.build excel
      @setState(
        doc: doc
        isModels: excel.name.toLowerCase().indexOf('models') != -1
        selectedWeek: 0
      ))

  changeWeek: (week)->
    @setState(
      selectedWeek: @state.doc.weeks.indexOf week
    )

  getInitialState: ->
    doc: null
    isModels: false
    selectedWeek: -1

  render: ->
    components = [
      div
        className: 'row',
        div
          className: 'col-md-12',
          DropZone {
            text: 'w13.xls or w13models.xls'
            onDropFile: @parseW13report
            className: if @state.doc then 'loaded' else 'empty'
          }
    ]
    if @state.doc?
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
                    weeks: @state.doc?.weeks
                    onChange: @changeWeek
                  }
                ]
      list = if @state.isModels
        MaterialModelsList {
          selectedWeek: @state.selectedWeek
          doc: @state.doc
        }
      else
        MaterialList {
          selectedWeek: @state.selectedWeek
          doc: @state.doc
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
    @props.onChange @getDOMNode().value.trim()

  render: ->
    options = (option({}, week) for week in @props.weeks ? [])
    select
      className: 'form-control'
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
    shortMaterials = (material for material in @props.doc?.materials ? [] when material.balanceSN[@props.selectedWeek] < 0)
    vendors = []
    vendors.push vendorName for vendorName in material.vendors when vendors.indexOf(vendorName) == -1 for material in shortMaterials

    filtered = shortMaterials
    if @state.selectedVendor isnt 'All'
      filtered = shortMaterials.filter (r)=>
        r.vendors.indexOf(@state.selectedVendor) isnt -1

    rows = for material in filtered
      tr {}, [
        td {}, material.name
        td {}, material.vendors.join(', ')
        td {}, material.purOrder
        td {className: 'negative'}, material.balanceSN[@props.selectedWeek]
        td {}, material.balanceSN[@props.selectedWeek + 1] ? ''
        td {}, material.balanceSN[@props.selectedWeek + 2] ? ''
      ]

    table
      className: 'table table-striped table-hover',
      [
        thead {},
          tr {}, [
            th {}, 'Material'
            th {}, VendorsList
              vendors: vendors
              onChange: @selectVendor
            th {}, 'Pur. Order'
            th {className: 'negative'}, @props.doc?.weeks[@props.selectedWeek]
            th {}, @props.doc?.weeks[@props.selectedWeek + 1] ? ''
            th {}, @props.doc?.weeks[@props.selectedWeek + 2] ? ''
          ]
        tbody {}, rows
      ]
}


VendorsList = React.createClass {
  onChange: ->
    @props.onChange @getDOMNode().value.trim()

  render: ->
    options = (option({}, vendor) for vendor in @props.vendors)
    options.unshift(option({}, 'All'))
    select
      className: 'form-control',
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