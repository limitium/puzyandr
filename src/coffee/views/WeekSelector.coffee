React = require 'react'

{select,option} = React.DOM

WeekSelector = React.createClass {
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

module.exports = WeekSelector