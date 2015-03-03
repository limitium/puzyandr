# Setup the dnd listeners.
dropZone = document.getElementById('drop_zone')
finder = document.getElementById('finder')
outputTbody = document.getElementById('output')
overdue = document.getElementById('overdue')

excels = []
handleFileSelect = (evt) ->
  evt.stopPropagation()
  evt.preventDefault()
  files = evt.dataTransfer.files
  # FileList object.
  # files is a FileList of File objects. List some properties.
  output = []
  excels.length = 0
  outputTbody.innerHTML = ""
  for file in files
    reader = new FileReader
    # Closure to capture the file information.
    reader.onload = ((theFile) ->
      (e) ->
        excelData = e.target.result
        excels.push excelData
    )(file)
    # Read in the image file as a data URL.
    reader.readAsText file
    output.push '<li><strong>', escape(file.name), '</strong></li>'
  document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>'
  return

find = ->
  if excels.length == 0
    alert "No excel file!"
    return
  if !overdue.value.trim()
    alert "No overdue!"
    return

  tableRows = []
  for excel in excels
    rows = excel.split "\n"
    headers = rows[3].split "\t"
    overdueName = overdue.value.trim()
    overdueIndx = headers.indexOf overdueName
    mrpIndx = headers.indexOf "MRP Elemen"
    for row,rowIndx in rows
      cells = row.split "\t"
      if cells[mrpIndx] is "Balance (S/N)" and cells[overdueIndx] < 0
        tableRows.push "<tr><td>#{rows[rowIndx-4].split("\t")[2]}</td><td>#{rows[rowIndx-3].split("\t")[2]}</td><td>#{cells[overdueIndx]}</td></tr>"
  outputTbody.innerHTML = tableRows.join("")

handleDragOver = (evt) ->
  evt.stopPropagation()
  evt.preventDefault()
  evt.dataTransfer.dropEffect = 'copy'
  # Explicitly show this is a copy.
  return

dropZone.addEventListener 'dragover', handleDragOver, false
dropZone.addEventListener 'drop', handleFileSelect, false
finder.addEventListener 'click', find, false