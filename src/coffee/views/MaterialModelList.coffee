React = require 'react'

{table,thead,tbody,tr,td,th} = React.DOM


MaterialModelsList = React.createClass {
  render: ->
    rows = for material in @props.w13doc.materials when material.balanceSN[@props.selectedWeek] < 0
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
          td {}, ''
          td {}, product.name
          td {}, product.qty
          td {}, qtyCanMade
          td {}, ''
        ]
      productsRows.unshift tr {className: 'negative' if short < 0}, [
        td {}, material.name
        td {}, material.vendors.join(', ')
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
            th {}, 'Vendors'
            th {}, 'Product'
            th {}, 'Forecast'
            th {}, 'Result'
            th {className: 'negative'}, @props.w13doc?.weeks[@props.selectedWeek]
          ]
        tbody {}, rows
      ]
}
module.exports = MaterialModelsList