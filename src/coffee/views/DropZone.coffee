React = require 'react'

{div,span} = React.DOM

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

module.exports = DropZone