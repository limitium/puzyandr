# Setup the dnd listeners.
dropZone = document.getElementById('drop_zone')
finder = document.getElementById('finder')
outputTbody = document.getElementById('output')
overdue = document.getElementById('overdue')
header = document.getElementById('header')

excels = []
handleFileSelect = (evt) ->
  evt.stopPropagation()
  evt.preventDefault()
  dropZone.classList.remove 'over'
  files = evt.dataTransfer.files
  # FileList object.
  # files is a FileList of File objects. List some properties.
  output = []
  excels.length = 0
  outputTbody.innerHTML = ""
  totalFiles = files.length
  totalLoaded = 0
  for file in files
    reader = new FileReader
    # Closure to capture the file information.
    reader.onload = ((theFile) ->
      (e) ->
        totalLoaded++
        excels.push excelToJSON(theFile.name, e.target.result)
        loaded() if totalFiles == totalLoaded
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
  for excel in excels
    headers = excel.rows[3]
    allWeeks.push(week) for week in headers[headers.indexOf("Overdue")+1..] when week not in allWeeks
  allWeeks.sort (w1,w2)-> w1 >= w2 ? 1 : -1

  overdue.innerHTML = "<option>"+allWeeks.join("</option><option>")+"</option>"
  find()

find = ->
  tableRows = []
  headers = excels[0].rows[3]
  headers = (h.trim() for h in headers)
  overdueName = overdue.value.trim()
  overdueIndx = headers.indexOf overdueName
  mrpIndx = headers.indexOf "MRP Elemen"

  for excel in excels
    tableRows.push "<tr class='excel-name'><td colspan='5'>#{excel.name}</td></tr>"
    for cells,rowIndx in excel.rows
      if cells[mrpIndx] is "Balance (S/N)" and cells[overdueIndx] < 0
        tableRows.push """
<tr>
  <td>#{excel.rows[rowIndx-4][2]}</td>
  <td>#{excel.rows[rowIndx-4][6]}</td>
  <td class='negative'>#{cells[overdueIndx]}</td>
  <td>#{cells[overdueIndx+1] ? ''}</td>
  <td>#{cells[overdueIndx+2] ? ''}</td>
</tr>
"""


  header.innerHTML = """
<th>Material</th>
<th>Vendor</th>
<th class='negative'>#{overdueName}</th>
<th>#{headers[overdueIndx+1] ? ''}</th>
<th>#{headers[overdueIndx+2] ? ''}</th>
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