W13Doc = require '../models/W13Doc.coffee'
W13Product = require '../models/W13Product.coffee'
W13Material = require '../models/W13Material.coffee'

class W13Builder
  @build: (excel)->
    doc = new W13Doc
    doc.weeks = @findWeeks excel
    doc.materials = @buildMaterials excel
    doc

  @findWeeks = (excel)->
    headers = excel.rows[3]
    (week.trim() for week in headers[headers.indexOf("Overdue") + 1..])

  @buildMaterials = (excel)->
    headers = excel.rows[3]
    mrpIndx = headers.indexOf "MRP Elemen"
    mrpIndx = headers.indexOf "MRP Element" if mrpIndx is -1
    materials = []

    material = null
    skipVendorDescription = false
    vendorsEnd = false
    hasBlocked = false
    for row in excel.rows[5...]
      if row[mrpIndx] is 'Requirements'
        material = new W13Material row[2].trim()
        materials.push material
        skipVendorDescription = false
        hasBlocked = false
        vendorsEnd = false

      if row[mrpIndx] is 'Balance (S/N)'
        material.balanceSN = ( parseInt(qty.replace(/\s/g, '')) for qty in row[headers.indexOf("Overdue") + 1..])

      if row[mrpIndx] is 'Pur. Order'
        material.purOrder = row[mrpIndx + 1]

      if row[mrpIndx - 2] is 'Blocked Stock'
        hasBlocked = true
      if row[mrpIndx - 2] is 'Subc.Stock'
        hasBlocked = false
        vendorsEnd = true

      if hasBlocked
        qty = ( parseInt(qty.replace(/\s/g, '')) for qty in row[headers.indexOf("Overdue") + 1..])
        material.blocked.push new W13Product(row[mrpIndx], qty)

      if row[6]?.trim() isnt '' and not vendorsEnd
        if !skipVendorDescription
          material.vendors.push row[6]?.trim()
          skipVendorDescription = true
        else
          skipVendorDescription = false

    materials

module.exports = W13Builder
