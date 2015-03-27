class ExcelParser
  @parse: (file, cb)->
    reader = new FileReader
    reader.onload = (e) =>
      cb @excelToJSON(escape(file.name), e.target.result)
    reader.readAsText file

  @excelToJSON: (name, excelText)->
    rows = [];
    rowsString = excelText.split "\n"
    for rowString in rowsString
      rows.push(rowString.split "\t")

    name: name
    rows: rows

class W13Doc
  weeks: []
  materials: []

class W13Material
  constructor: (@name)->
    @vendors = []
    @blocked = []
    @balanceSN = []
    @purOrder = null


class W13Product
  constructor: (@name, @qty)->

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
    materials = []

    material = null
    skipVendorDescription = false
    vendorsEnd = false
    hasBlocked = false
    for row in excel.rows[5...]
      if row[mrpIndx] is 'Requirements'
        materials.push material if material
        material = new W13Material row[2].trim()
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


class POVendor
  constructor: (@name)->
    @qty = 0


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


class PODoc
  constructor: ->
    @materials= {}

  getMaterial: (name)->
    if @materials[name]?
      @materials[name]
    else
      material = new POMaterial(name)
      @materials[name] = material
      material


class POBuilder
  @build: (excel)->
    doc = new PODoc
    doc.getMaterial(row[1].trim()).getVendor(row[4].trim()).qty += parseInt(row[25].replace(/\s/g, '')) for row in excel.rows[6..] when row[25]?
    doc
