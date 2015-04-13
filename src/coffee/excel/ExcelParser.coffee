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


module.exports = ExcelParser