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


class W13Product
  constructor: (@name, @qty)->

class W13Builder
  @build: (excel)->
    doc = new W13Doc
    doc.weeks = @findWeeks excel
    doc.materials = @buildMaterials excel
    console.log doc
    doc

  @findWeeks = (excel)->
    headers = excel.rows[3]
    weeks = (week.trim() for week in headers[headers.indexOf("Overdue") + 1..])
    weeks.sort (w1, w2)-> w1 >= w2 ? 1: -1

  @buildMaterials = (excel)->
    headers = excel.rows[3]
    mrpIndx = headers.indexOf "MRP Elemen"
    materials = []

    material = null
    skipVendorDescription = false
    hasBlocked = false
    for row in excel.rows[5...]
      if row[mrpIndx] is 'Requirements'
        materials.push material if material
        material = new W13Material row[2]
        skipVendorDescription = false
        hasBlocked = false

      if row[mrpIndx] is 'Balance (S/N)'
        material.balanceSN.push parseInt(qty.replace(/\s/g, '')) for qty in row[headers.indexOf("Overdue") + 1..]

      if row[mrpIndx - 2] is 'Blocked Stock'
        hasBlocked = true
      if row[mrpIndx - 2] is 'Subc.Stock'
        hasBlocked = false

      if hasBlocked
        qty = ( parseInt(qty.replace(/\s/g, '')) for qty in row[headers.indexOf("Overdue") + 1..])
        material.blocked.push new W13Product(row[mrpIndx], qty)

      if row[6]?.trim() isnt ''
        if !skipVendorDescription
          material.vendors.push row[6]?.trim()
          skipVendorDescription = true
        else
          skipVendorDescription = false

    materials

dropZone = document.getElementById('drop_zone')
finder = document.getElementById('finder')
outputTbody = document.getElementById('output')
overdue = document.getElementById('overdue')
vendor = document.getElementById('vendor')
header = document.getElementById('header')

isModels = false
doc = null

handleFileSelect = (evt) ->
  evt.stopPropagation()
  evt.preventDefault()
  dropZone.classList.remove 'over'
  files = evt.dataTransfer.files
  ExcelParser.parse(files[0], (excel)-> loaded(excel))


loaded = (excel)->
  doc = W13Builder.build excel
  isModels = excel.name.toLowerCase().indexOf('models') != -1
  overdue.innerHTML = "<option>" + doc.weeks.join("</option><option>") + "</option>"
  render()


render = ()->
  overdueName = overdue.value.trim()
  overdueIndx = doc.weeks.indexOf overdueName
  if isModels
    renderModels(doc, overdueIndx)
  else
    renderShort(doc, overdueIndx)

shortMaterials = []
ovi = 0
renderShort = (doc, overdueIndx)->
  ovi = overdueIndx
  header.innerHTML = """
<th>Material</th>
<th>Vendor</th>
<th class='negative'>#{doc.weeks[overdueIndx] ? ''}</th>
<th>#{doc.weeks[overdueIndx+1] ? ''}</th>
<th>#{doc.weeks[overdueIndx+2] ? ''}</th>
  """
  shortMaterials = (material for material in doc.materials when material.balanceSN[overdueIndx] < 0)
  vendors = []
  vendors.push vendorName for vendorName in material.vendors when vendors.indexOf(vendorName) == -1 for material in shortMaterials
  vendor.innerHTML = "<option></option><option>" + vendors.join("</option><option>") + "</option>"
  vendor.value = ''
  filterByVendor()

filterByVendor = ->
  vendorName = vendor.value.trim()
  filtered = shortMaterials
  if vendorName isnt ''
    filtered = shortMaterials.filter (r)->
      r.vendors.indexOf(vendorName) isnt -1

  tableRows = []
  for material in filtered
    tableRows.push """
<tr>
  <td>#{material.name}</td>
  <td>#{material.vendors.join(', ')}</td>
  <td class='negative'>#{material.balanceSN[ovi]}</td>
  <td>#{material.balanceSN[ovi+1] ? ''}</td>
  <td>#{material.balanceSN[ovi+2] ? ''}</td>
</tr>
"""
  outputTbody.innerHTML = tableRows.join("")

renderModels = (doc, overdueIndx)->
  header.innerHTML = """
<th>Material</th>
<th>Product</th>
<th>Forecast</th>
<th>Result</th>
<th class='negative'>#{doc.weeks[overdueIndx]}</th>
  """
  tableRows = []
  for material in doc.materials when material.balanceSN[overdueIndx] < 0
    short = material.balanceSN[overdueIndx]
    productsRows = []

    productForReduce = (name: product.name, qty: product.qty[overdueIndx] for product in material.blocked when product.qty[overdueIndx] > 0)
    productForReduce.sort (p1, p2)-> p2.qty - p1.qty

    for product in productForReduce when short < 0
      qtyCanMade = product.qty + short
      if qtyCanMade < 0
        short = qtyCanMade
        qtyCanMade = 0
      else
        short = 0

      productsRows.push """
      <tr>
        <td></td>
        <td>#{product.name}</td>
        <td>#{product.qty}</td>
        <td>#{qtyCanMade}</td>
        <td></td>
      </tr>
      """
    tableRows.push """
    <tr class='#{'negative' if short <0}'>
        <td>#{material.name}</td>
        <td></td>
        <td></td>
        <td>#{short}</td>
        <td class='negative'>#{material.balanceSN[overdueIndx]}</td>
      </tr>
    """
    tableRows.push row for row in productsRows
  outputTbody.innerHTML = tableRows.join("")


handleDragOver = (evt) ->
  evt.stopPropagation()
  evt.preventDefault()
  evt.dataTransfer.dropEffect = 'copy'
  dropZone.classList.add 'over'
  # Explicitly show this is a copy.
  return

handleDragLeave = (evt) ->
  dropZone.classList.remove 'over'

fff = ->
  filterByVendor() if !isModels

dropZone.addEventListener 'dragover', handleDragOver, false
dropZone.addEventListener 'dragleave', handleDragLeave, false
dropZone.addEventListener 'drop', handleFileSelect, false
overdue.addEventListener 'change', render, false
vendor.addEventListener 'change', fff, false