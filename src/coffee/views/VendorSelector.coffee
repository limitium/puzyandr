React = require 'react'

{select,option} = React.DOM

VendorSelector = React.createClass {
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
module.exports = VendorSelector
