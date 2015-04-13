ExcelParser = require './../excel/ExcelParser.coffee'
W13Builder = require './../excel/W13Builder.coffee'
POBuilder = require './../excel/POBuilder.coffee'

DropZone = require './DropZone.coffee'
WeekSelector = require './WeekSelector.coffee'
MaterialModelsList = require './MaterialModelList.coffee'
MaterialList = require './MaterialList.coffee'

React = require 'react'

{div,h3,hr,label} = React.DOM


SamsApp = React.createClass {
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
                  WeekSelector {
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

module.exports = SamsApp




