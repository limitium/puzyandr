POVendor = require './POVendor.coffee'

class POMaterial
  constructor: (@name)->
    @vendors = {}

  getVendor: (name)->
    if @vendors[name]?
      @vendors[name]
    else
      vendor = new POVendor(name)
      @vendors[name] = vendor
      vendor

module.exports = POMaterial
