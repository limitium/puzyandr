# Setup the dnd listeners.
dropZone = document.getElementById('drop_zone')
finder = document.getElementById('finder')
outputTbody = document.getElementById('output')
overdue = document.getElementById('overdue')
vendor = document.getElementById('vendor')
header = document.getElementById('header')

excel = null
materials = []

handleFileSelect = (evt) ->
  evt.stopPropagation()
  evt.preventDefault()
  dropZone.classList.remove 'over'
  files = evt.dataTransfer.files
  # FileList object.
  # files is a FileList of File objects. List some properties.
  output = []
  outputTbody.innerHTML = ""
  for file in files
    reader = new FileReader
    # Closure to capture the file information.
    reader.onload = ((theFile) ->
      (e) ->
        excel = excelToJSON(theFile.name, e.target.result)
        loaded()
    )(file)
    # Read in the image file as a data URL.
    reader.readAsText file
    output.push '<li><strong>', escape(file.name), '</strong></li>'
  document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>'
  return

excelToJSON = (name, excel)->
  rows = [];
  rowsString = excel.split "\n"
  for rowString in rowsString
    rows.push(rowString.split "\t")

  name: name
  rows: rows

loaded = ->
  allWeeks = []
  headers = excel.rows[3]
  allWeeks.push(week) for week in headers[headers.indexOf("Overdue")+1..] when week not in allWeeks
  allWeeks.sort (w1,w2)-> w1 >= w2 ? 1 : -1

  overdue.innerHTML = "<option>"+allWeeks.join("</option><option>")+"</option>"
  find()

find = ->
  headers = excel.rows[3]
  headers = (h.trim() for h in headers)
  overdueName = overdue.value.trim()
  overdueIndx = headers.indexOf overdueName
  header.innerHTML = """
<th>Material</th>
<th>Vendor</th>
<th class='negative'>#{overdueName}</th>
<th>#{headers[overdueIndx+1] ? ''}</th>
<th>#{headers[overdueIndx+2] ? ''}</th>
  """

  materials.length = 0
  mrpIndx = headers.indexOf "MRP Elemen"
  vendors = []
  for cells,rowIndx in excel.rows when cells[mrpIndx] is "Balance (S/N)" and cells[overdueIndx] < 0
    materialVendors = findVendors excel.rows, rowIndx-4, mrpIndx
    vendors.push v for v in materialVendors when vendors.indexOf(v) is -1

    materials.push
      name: excel.rows[rowIndx-4][2]
      vendors: materialVendors
      qty: cells[overdueIndx]
      qtyw1: cells[overdueIndx+1] ? ''
      qtyw2: cells[overdueIndx+2] ? ''

  vendor.innerHTML = "<option></option><option>"+vendors.join("</option><option>")+"</option>"
  vendor.value=''
  filter()

findVendors = (rows, from, mrpIndx)->
  end = rows.length
  end = from + 6 if rows?[from+6]?[mrpIndx] is 'Requirements'
  end = from + 8 if rows?[from+8]?[mrpIndx] is 'Requirements'
  vendors = []
  for rowInd in [from...end]
    if rows?[rowInd]?[6]?.trim() isnt ''
      if !skip
        vendors.push rows[rowInd][6]
        skip = true
      else
        skip = false
  vendors
filter = ->
  vendorName = vendor.value.trim()
  filtered = materials
  if vendorName isnt ''
    filtered = materials.filter (r)->
      r.vendors.indexOf(vendorName) isnt -1

  tableRows=[]
  for material in filtered
    tableRows.push """
<tr>
  <td>#{material.name}</td>
  <td>#{material.vendors.join(',')}</td>
  <td class='negative'>#{material.qty}</td>
  <td>#{material.qtyw1}</td>
  <td>#{material.qtyw2}</td>
</tr>
"""
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

dropZone.addEventListener 'dragover', handleDragOver, false
dropZone.addEventListener 'dragleave', handleDragLeave, false
dropZone.addEventListener 'drop', handleFileSelect, false
overdue.addEventListener 'change', find, false
vendor.addEventListener 'change', filter, false