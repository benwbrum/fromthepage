import { Controller } from "@hotwired/stimulus"

import "plugins/handsontable.full.min";

// Connects to data-controller="handsontable"
export default class extends Controller {

  static values = {
    columns: Array,
    content: Array,
    dateTooltip: String,
    transcriptionField: Object,
  }

  connect() {
    this._handsontable = new Handsontable(this.element, {
      rowHeaders: true,
      colHeaders: this.columnHeadersConfig(),
      filters: true,
      comments: true,
      data: this.dataConfig(),
      width: '100%',
      rowHeights: 23,
      columnHeaderHeight: 25,
      height: this.getHotHeight(this.dataConfig() ? this.dataConfig().length : this.transcriptionFieldValue.starting_rows),
      stretchH: 'all',
      contextMenu: ['row_above', 'row_below', 'remove_row', 'undo', 'redo', 'cut', 'copy'],
      dropdownMenu: true,
      columns: this.columnsConfig(),
      autoWrapCol: true,
      manualColumnResize: true,
      manualRowResize: true,
      startRows: this.transcriptionFieldValue.starting_rows,
    });

    this._handsontable.updateSettings({
      afterCreateRow: this.updateHotHeight.bind(this),
      afterRemoveRow: this.updateHotHeight.bind(this),
      afterChange: this.afterChangeCallback.bind(this),
      afterSelection: this.afterSelectionCallback.bind(this),
      modifyColWidth: function(width, col) {
        if (width > 300) {
          return 300
        }
      }
    });

    window.addEventListener('load', function() {
      window.onscroll = function (e) {
        window.freezeTableColumn();
      }
    })

    document.getElementById(`fields-${this.transcriptionFieldValue.id}`).value = JSON.stringify(this._handsontable.getData());

    this._handsontable.validateCells();
  }

  columnsConfig() {
    if (!this._columnsConfig) {
      this._columnsConfig = this.columnsValue.map(column => {
        let config = {};

        if (column.input_type === "select") {
          config.type = "autocomplete";
          config.strict = true;
          config.allowInvalid = true;
          config.source = column.options ? column.options.split(";") : [];
        } else if (column.input_type === "numeric") {
          config.type = "numeric";
        } else if (column.input_type === "checkbox") {
          config.type = "checkbox";
        } else if (column.input_type === "date") {
          config.validator = this.edtfValidator.bind(this);
          config.placeholder = "YYYY-MM-DD";
          config.comment = { value: this.dateTooltipValue };
        }

        return config;
      });
    }

    return this._columnsConfig;
  }

  edtfValidator(value, callback) {
    setTimeout(() => {
      const validFormat = /^(1[4-9]|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/;
      callback(validFormat.test(value) || !value);
    }, 100);
  }

  columnHeadersConfig() {
    if (!this._columnHeadersConfig) {
      this._columnHeadersConfig = this.columnsValue.map(column => { return column.label });
    }

    return this._columnHeadersConfig;
  }

  dataConfig() {
    if (!this._dataConfig) {
      this._dataConfig = this.contentValue.map(row => {
        return this.columnsValue.map(column => {
          let value = row[column.id];

          if (column.input_type === 'checkbox') {
            value = (value == 'true') || value ? 'true' : 'false';
          }

          return value;
        });
      });
    }

    return this._dataConfig
  }

  getHotHeight(rows) {
    return rows * 23 + 40;
  };

  updateHotHeight() {
    document.getElementById(`fields-${this.transcriptionFieldValue.id}`).value = JSON.stringify(this._handsontable.getData());

    this._handsontable.updateSettings(
      { height: this.getHotHeight(this._handsontable.countRows()) }
    );
  }

  afterChangeCallback(changes, source) {
    if (source === 'edit') {
      window.sendActiveEditing();
    }

    document.getElementById(`fields-${this.transcriptionFieldValue.id}`).value = JSON.stringify(this._handsontable.getData());

    if (changes) {
      let rowsCount = this._handsontable.countRows();
      changes.forEach(([row, prop, oldValue, newValue]) => {
        if (row + 1 === rowsCount) {
          this._handsontable.alter('insert_row', rowsCount);
        }
      });
    }
  }

  afterSelectionCallback(row, column, row2, column2, preventScrolling, selectionLayerLevel) {
    if (this.transcriptionFieldValue.row_highlight) {
      this.highlightRow(
        row,
        this.transcriptionFieldValue.starting_row,
        this.transcriptionFieldValue.top_offset,
        this.transcriptionFieldValue.bottom_offset
      );
    }
  }

  highlightRow(rowNum, maxRows, topOffset, bottomOffset) {
    // first calculate against a 100% high canvas
    rowHeightAsSpreadsheetPct = 1.0 / maxRows;

    pctOfPageThatIsSpreadsheet = (1.0 - topOffset - bottomOffset);
    rowHeightAsPagePct = pctOfPageThatIsSpreadsheet / maxRows;
    margin = 0.005;
    fuzzyRowHeightAsPagePct = rowHeightAsPagePct + (margin * 2);

    rowOffsetFromPageTop = topOffset + (rowHeightAsPagePct*(rowNum));
    fuzzyRowOffsetFromPageTop = rowOffsetFromPageTop - margin;

    if (window.viewer.world.getItemCount() > 0) {
      // now transpose for viewport coordinates
      viewportY = fuzzyRowOffsetFromPageTop * window.viewer.world.getItemAt(0).normHeight;
      viewportHeight = fuzzyRowHeightAsPagePct * window.viewer.world.getItemAt(0).normHeight;
      // console.log("highlightRow("+rowNum+", "+maxRows+", "+topOffset+", "+bottomOffset+") setting viewportY="+viewportY);

      window.viewer.removeOverlay("runtime-overlay");

      var elt = document.createElement("div");
      elt.id = "runtime-overlay";
      elt.className = "image-row-highlight";
      console.log('here');
      window.viewer.addOverlay({
        element: elt,
        location: new OpenSeadragon.Rect(0.0, viewportY, 1.0, viewportHeight)
      });
    }
  };
}
