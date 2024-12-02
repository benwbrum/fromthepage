// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery.ui.all
//= require jquery_ujs
//= require_tree ./plugins
//= require user.js
//= require handsontable.full.min
//= require datatables.min
//= require clipboard
//= require select_all
//= require utils

$(function() {
  $('.flash').flashclose();
  $('.dropdown').dropdown();
  $('.input-file').inputFile();
  $('[data-litebox]').litebox();
  $('[data-tooltip]').tooltip();
  $('[data-fullheight]').fullheight();
  $('[data-imageview]').imageView();

  // Classname trigger
  $(document).on('click', '[data-toggle-class]', function() {
    var data = $(this).data('toggle-class');
    for(var selector in data) {
      $(selector).toggleClass(data[selector]);
    }
  });

  // Global page loading spinner
  $('html').removeClass('page-busy');
  $(window)
    .ajaxStart(function() { $('html').addClass('page-busy'); })
    .ajaxComplete(function() { $('html').removeClass('page-busy'); });

  // Warn about unsaved data
  $('form[data-areyousure]').areYouSure();

  // Show and hide collection statistics
  $('.collection').on('click', '[data-toggle-stats]', function(e) {
    var container = $(e.delegateTarget);
    var stats = $('.collection_stats', container);
    var ishidden = stats.is(':hidden');
    stats[ishidden ? 'slideDown' : 'slideUp']('fast');
    container.toggleClass('stats-visible', ishidden);
  });

  // Manage subject categories
  $('[data-assign-categories]').categoriesSelect();

  $('[data-multi-select]').multiSelect();

  $('[data-select-all]').selectAll();

  // Filterable table
  $('[data-filterable-table]').filterableTable();

  // Category tree expand/collapse
  $('.tree-bullet').on('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).closest('li').toggleClass('expanded');
  });

  // Disable export button when no format options selected
  var exportCheckboxes = $('.bulk-export_options input');
  exportCheckboxes.change(function() {
    $(this).closest('form')
      .find('button[type=submit]')
      .prop('disabled', exportCheckboxes.filter(':checked').length < 1);
  });
  exportCheckboxes.change();

  // Tippy tooltips
  tippy('[data-tippy-content]', {
    placement: 'bottom-start',
    duration: [100, 200],
    maxWidth: 300,
  });
});

//Enable and disable select options for field-based transcription
function addOptions(selector, enabled_index){
  var parentTr = selector.parentElement.parentElement;
  var optionsObj = $(parentTr).find('td .field-options')[0];
  var index = selector.options.selectedIndex;
  if (index == enabled_index){
    $(optionsObj).prop('disabled', false);
  } else {
    $(optionsObj).prop('disabled', true);
  }
};

//Default options for DataTables
Object.assign(DataTable.defaults, {
  // pagination count options
  "lengthMenu": [ [10, 50, -1], [10, 50, "All"] ],

  "drawCallback": function(oSettings) {
    // don't show pagination if only one page
    if (oSettings._iDisplayLength >= oSettings.fnRecordsDisplay() || oSettings._iDisplayLength == -1) {
        $(oSettings.nTableWrapper).find('.dataTables_paginate').hide();
    } else {
        $(oSettings.nTableWrapper).find('.dataTables_paginate').show();
    }

    // don't show pagination count selector if less than 10 items
    if (oSettings.fnRecordsDisplay() < 10) {
        $(oSettings.nTableWrapper).find('.dataTables_length').hide();
    } else {
        $(oSettings.nTableWrapper).find('.dataTables_length').show();
    }
  }
});

// prevent double confirmation popup when deleting topic in forum
$(document).ready(function() {
  const deleteTopicBtn = ($('input[data-confirm]'))
  const confirmTxt = $('input[data-confirm]').attr('data-confirm');

  $('input[data-confirm]').removeAttr('data-confirm');
  $(deleteTopicBtn).on('click', function(){
    event.preventDefault();
    var confirmation = confirm(confirmTxt);
    if (confirmation) {
      $(this).closest('form').submit();
    }
  })
})

function refreshEditors() {
  if(typeof hot !== 'undefined') {
    hot.updateSettings({});
  }

  if(typeof myCodeMirror !== 'undefined') {
    myCodeMirror.refresh();
  }
}

function undoCodeMirror() {
  if(typeof myCodeMirror !== 'undefined') {
    myCodeMirror.undo();
  }
}

function redoCodeMirror() {
  if(typeof myCodeMirror !== 'undefined') {
    myCodeMirror.redo();
  }
}

const ResizableSplitter = {
  initVertical: function makeResiableSplitter(splitterSelector, panel1Selector, panel2Selector, mode='', options = {}) {
    const { onDrag, onChanged, initialPosition = '50%', onPositionChange } = options;

    const splitter = document.querySelector(splitterSelector);
    const panel1 = document.querySelector(panel1Selector);
    const panel2 = document.querySelector(panel2Selector);

    let startX;
    let startWidthPanel1;
    let startWidthPanel2;

    splitter.style.top = '0px';

    // Function to calculate initial widths based on initial position
    const calculateInitialWidths = function(position) {
      const totalWidth = panel1.offsetWidth + panel2.offsetWidth;
      const initialWidth = typeof position === 'string' && position.includes('%')
        ? parseFloat(position) / 100 * window.innerWidth
        : parseFloat(position);

      const widthPanel1 = initialWidth;
      const widthPanel2 = window.innerWidth - initialWidth;

      return {
        widthPanel1,
        widthPanel2
      };
    };

    const { widthPanel1, widthPanel2 } = calculateInitialWidths(initialPosition);

    panel1.style.flex = `${widthPanel1}px`;
    panel2.style.flex = `${widthPanel2}px`;

    // Function to handle mouse move
    const onMouseMove = function(e) {
      const deltaX = e.clientX - startX;
      const totalWidth = panel1.offsetWidth + panel2.offsetWidth;
      const newWidthPanel1 = startWidthPanel1 + deltaX;
      const newWidthPanel2 = startWidthPanel2 - deltaX;

      panel1.style.flex = `${newWidthPanel1}px`;
      panel2.style.flex = `${newWidthPanel2}px`;

      if (typeof onPositionChange === 'function') {
        const currentPosition = (newWidthPanel1 / totalWidth) * 100;
        onPositionChange(currentPosition);
      }

      if (typeof onDrag === 'function') {
        onDrag(newWidthPanel1, newWidthPanel2);
      }
    };

    // Function to handle mouse up
    const onMouseUp = function() {
      if (typeof onChanged === 'function') {
        onChanged(panel1.offsetWidth, panel2.offsetWidth);
      }

      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
    };

    // Function to handle mouse down
    const onMouseDown = function(e) {
      startX = e.clientX;
      startWidthPanel1 = panel1.offsetWidth;
      startWidthPanel2 = panel2.offsetWidth;

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    };

    splitter.addEventListener('mousedown', onMouseDown);

    // Handle window resize event
    const handleWindowResize = function() {
      const totalWidth = panel1.offsetWidth + panel2.offsetWidth;
      const newWidthPanel1 = (panel1.offsetWidth / totalWidth) * window.innerWidth;
      const newWidthPanel2 = window.innerWidth - newWidthPanel1;

      panel1.style.flex = `${newWidthPanel1 / window.innerWidth}`;
      panel2.style.flex = `${newWidthPanel2 / window.innerWidth}`;
    };

    window.addEventListener('resize', handleWindowResize);

    // Initial adjustment on load
    handleWindowResize();

    // Method to remove event listeners
    this.destroy = function() {
      splitter.removeEventListener('mousedown', onMouseDown);
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
      window.removeEventListener('resize', handleWindowResize);
    };
  },

  initHorizontal: function(splitterSelector, panel1Selector, panel2Selector, mode='', options = {}) {
    const { onDrag, onChanged, initialPosition = '50%', onPositionChange } = options;

    const splitter = document.querySelector(splitterSelector);
    const panel1 = document.querySelector(panel1Selector);
    const panel2 = document.querySelector(panel2Selector);

    let startY;
    let startHeightPanel1;
    let startHeightPanel2;

    // Function to calculate initial heights based on initial position
    const calculateInitialHeights = function(position) {
      const totalHeight = panel1.parentElement.offsetHeight;
      const initialHeight = typeof position === 'string' && position.includes('%')
        ? parseFloat(position) / 100 * totalHeight
        : parseFloat(position);

      const heightPanel1 = initialHeight;
      const heightPanel2 = totalHeight - initialHeight;

      return {
        heightPanel1,
        heightPanel2
      };
    };

    const { heightPanel1, heightPanel2 } = calculateInitialHeights(initialPosition);

    panel1.style.flex = mode === 'ttb'?`${heightPanel1}px`:'auto';
    panel2.style.flex = mode === 'ttb'?`auto`:`${heightPanel2}px`;

    const resetSplitterPos = () => {
      if(mode === 'ttb') {
        const elementTop = Math.abs(panel1.parentElement.offsetTop - window.scrollTop);
        splitter.style.top = `${elementTop > 73?elementTop:73 + panel1.clientHeight}px`;
        splitter.style.bottom = `auto`;
      } else {
        splitter.style.bottom = `${panel2.clientHeight}px`
        splitter.style.top = `auto`;
      }
    }

    resetSplitterPos();

    // Function to handle mouse move
    const onMouseMove = function(e) {
      const deltaY = e.clientY - startY;
      let newHeightPanel1 = startHeightPanel1;

      if(mode === 'ttb') {
        newHeightPanel1 = startHeightPanel1 + deltaY;
      } else {
        newHeightPanel1 = startHeightPanel1 - deltaY;
      }

      if(mode === 'ttb') {
        panel1.style.flex = `${newHeightPanel1}px`;
      } else {
        panel2.style.flex = `${newHeightPanel1}px`;
      }

      if (typeof onPositionChange === 'function') {
        const totalHeight = panel1.parentElement.offsetHeight;
        const currentPosition = (newHeightPanel1 / totalHeight) * 100;
        onPositionChange(currentPosition);
      }

      if (typeof onDrag === 'function') {
        onDrag(newHeightPanel1, heightPanel2);
      }

      resetSplitterPos();
    };

    // Function to handle mouse up
    const onMouseUp = function() {
      if (typeof onChanged === 'function') {
        onChanged(panel1.offsetHeight, panel2.offsetHeight);
      }

      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
    };

    // Function to handle mouse down
    const onMouseDown = function(e) {
      startY = e.clientY;
      if(mode === 'ttb') {
        startHeightPanel1 = panel1.offsetHeight;
      } else {
        startHeightPanel1 = panel2.offsetHeight;
      }

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    };

    splitter.addEventListener('mousedown', onMouseDown);

    window.addEventListener('scroll', resetSplitterPos);

    // Method to remove event listeners
    this.destroy = function() {
      splitter.removeEventListener('mousedown', onMouseDown);
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
      window.removeEventListener('scroll', resetSplitterPos);
    };
  }
}

function freezeTableColumn(topEl, tableEl, columnEl, mode='') {
  if($('[data-layout-set]').length) {
    var mode = $('.page-columns').attr('data-layout-mode');
    var topEl = '';
    var tableEl = '.spreadsheet';
    var columnEl = '.ht_clone_top';

    if(mode === 'ttb') {
      topEl = '.page-imagescan'
    } else {
      topEl = '.page-toolbar'
    }

    var stickyHeight = document.querySelector(topEl).clientHeight + document.querySelector(topEl).getBoundingClientRect().top;
    var tablePosTop = document.querySelector(tableEl).getBoundingClientRect().top;

    if(stickyHeight > tablePosTop) {
      document.querySelectorAll(columnEl).forEach(function(item) {
        item.style.top = (stickyHeight - tablePosTop) + (mode === 'ttb'?20:0) + 'px';
        item.style.zIndex = 103;
      })
    } else {
      document.querySelectorAll(columnEl).forEach(function(item) {
        item.style.top = '0px';
      })
    }
  }
}
