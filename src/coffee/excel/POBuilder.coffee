PODoc = require '../models/PODoc.coffee'

class POBuilder
  @build: (excel)->
    doc = new PODoc
    doc.getMaterial(row[1].trim()).getVendor(row[4].trim()).qty += parseInt(row[25].replace(/\s/g, '')) for row in excel.rows[6..] when row[25]?
    doc

module.exports = POBuilder