VendorSelector = require './VendorSelector.coffee'

React = require 'react'

{table,thead,tbody,tr,td,th} = React.DOM

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
      th {}, VendorSelector
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

module.exports = MaterialList
