function compareTables(table1, table2) {
  var resultTable = $('<table></table>');
  var numRows = Math.max(table1.find('tr').length, table2.find('tr').length);
  for (var i = 0; i < numRows; i++) {
    var row1 = table1.find('tr:eq(' + i + ')');
    var row2 = table2.find('tr:eq(' + i + ')');
    var resultRow = $('<tr></tr>');
    var numCells = Math.max(row1.find('td').length, row2.find('td').length);
    for (var j = 0; j < numCells; j++) {
      var cell1 = row1.find('td:eq(' + j + ')');
      var cell2 = row2.find('td:eq(' + j + ')');
      var text1 = cell1.text().trim();
      var text2 = cell2.text().trim();
      var resultCell = $('<td></td>');
      if (text1 === text2) {
        resultCell.text(text1);
      } else {
        var deletedText = '<span><del>' + text1 + '</del></span>';
        var insertedText = '<span><ins>' + text2 + '</ins></span>';
        resultCell.html(deletedText + ' ' + insertedText);
      }
      resultRow.append(resultCell);
    }
    resultTable.append(resultRow);
  }
  return resultTable;
}