POMaterial = require './POMaterial.coffee'

class PODoc
  constructor: ->
    @materials = {}

  getMaterial: (name)->
    if @materials[name]?
      @materials[name]
    else
      material = new POMaterial(name)
      @materials[name] = material
      material

module.exports = PODoc