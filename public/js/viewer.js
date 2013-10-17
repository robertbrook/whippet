var scale;
var pdf_file;
var current_page;

function getUrlParams() {
  var result = {};
  var paramParts;
  var params = (window.location.search.split('?')[1] || '').split('&');
  for(var param in params) {
    if (params.hasOwnProperty(param)) {
      paramParts = params[param].split('=');
      result[paramParts[0]] = decodeURIComponent(paramParts[1] || "");
    }
  }
  return result;
}

function loadPdf(file, page_num) {
  var promise = $.Deferred();
  var pdf = PDFJS.getDocument(file);
  pdf.then(function(result) {
    current_page = page_num;
    renderPdf(result, page_num, file).then(function() {
      promise.resolve()
    });
  });
  return promise.promise();
}

function renderPdf(pdf, page_no, filename){
  var promise = $.Deferred();
  $prevButton = jQuery("#previous");
  $nextButton = jQuery("#next");
  if (page_no > 1) {
    $prevButton.attr('href', 'javascript:loadPdf("' + filename + '",' + (page_no - 1) + ')');
    $prevButton.removeClass("disabled");
  } else {
    $prevButton.attr('href', '#');
    $prevButton.addClass("disabled");
  }
  if (page_no < pdf.numPages) {
    $nextButton.attr('href', 'javascript:loadPdf("' + filename + '",' + (page_no + 1) + ')');
    $nextButton.removeClass("disabled");
  } else {
    $nextButton.attr('href', '#');
    $nextButton.addClass("disabled");
  }
  pdf.getPage(page_no).then(function(page) {
    renderPage(page).then(function() {
      promise.resolve();
    });
  });
  return promise.promise();
}

function drawControlBar(currentPage) {
  var $controlbarContainer = jQuery("#controlBar");
  var $prevButton = jQuery("<a id='previous' href='#'>&laquo;</a>");
  $controlbarContainer.append($prevButton);
  var $nextButton = jQuery("<a id='next' href='#'>&raquo;</a>");
  $controlbarContainer.append($nextButton);
}

function renderPage(page) {
  var promise = $.Deferred();
  var viewport = page.getViewport(scale);
  var $canvas = jQuery("<canvas></canvas>");
  
  //Set the canvas height and width to the height and width of the viewport
  var canvas = $canvas.get(0);
  var context = canvas.getContext("2d");
  canvas.height = viewport.height;
  canvas.width = viewport.width;
  var $controlbarContainer = jQuery("#controlBar");
  $controlbarContainer.css("width", canvas.width + 2 + "px");
  
  var $pdfContainer = jQuery("#pdfContainer");
  
  //Clear previous textLayers
  $pdfContainer.empty();
  
  //Append the canvas to the pdf container div
  $pdfContainer.css("height", canvas.height + 2 + "px").css("width", canvas.width + 2 + "px");
  $pdfContainer.append($canvas);
  
  //The following few lines of code set up scaling on the context if we are on a HiDPI display
  var outputScale = getOutputScale();
  if (outputScale.scaled) {
      var cssScale = 'scale(' + (1 / outputScale.sx) + ', ' +
          (1 / outputScale.sy) + ')';
      CustomStyle.setProp('transform', canvas, cssScale);
      CustomStyle.setProp('transformOrigin', canvas, '0% 0%');
      
      if ($textLayerDiv.get(0)) {
          CustomStyle.setProp('transform', $textLayerDiv.get(0), cssScale);
          CustomStyle.setProp('transformOrigin', $textLayerDiv.get(0), '0% 0%');
      }
  }
  
  context._scaleX = outputScale.sx;
  context._scaleY = outputScale.sy;
  if (outputScale.scaled) {
      context.scale(outputScale.sx, outputScale.sy);
  }
  
  var $textLayerDiv = jQuery("<div />")
      .addClass("textLayer")
      .css("height", viewport.height + "px")
      .css("width", viewport.width + "px")
      .offset({
          top: 0,
          left: 0
      });
  
  //Append the text-layer div to the DOM as a child of the PDF container div.
  $pdfContainer.append($textLayerDiv);
  
  page.getTextContent().then(function (textContent) {
      var textLayer = new TextLayerBuilder($textLayerDiv.get(0), 0); //The second zero is an index identifying
      //the page. It is set to page.number - 1.
      textLayer.setTextContent(textContent);
      
      var renderContext = {
          canvasContext: context,
          viewport: viewport,
          textLayer: textLayer
      };
      
      page.render(renderContext).then(function(){
        promise.resolve()
      });
  });
  return promise.promise();
}

function highlightLine(line_no) {
  $( "div#line-" + line_no ).addClass("chosen");
}

function removeAllHighlights() {
  $( ".chosen" ).removeClass("chosen");
}

function highlightLines(first_no, last_no) {
  for (var line_no = first_no; line_no <= last_no; line_no++) {
    highlightLine(line_no);
  }
}

function highlightPdfLine(file, page_no, line_no) {
  removeAllHighlights();
  if (pdf_file != file || page_no != current_page) {
    loadPdf("/pdf/" + file, page_no).then(function() {
      highlightLine(line_no);
    });
  } else {
    highlightLine(line_no);
  }
}

function highlightPdfLines(file, page_no, start_line, end_line) {
  removeAllHighlights();
  if (pdf_file != file || page_no != current_page) {
    loadPdf("/pdf/" + file, page_no).then(function() {
      highlightLines(start_line, end_line);
    });
  }
  highlightLines(start_line, end_line);
}

function drawViewer(size, file, page_no) {
  PDFJS.disableWorker = true; //Not using web workers. Not disabling results in an error.
  scale = size; //Set this to whatever you want. This is basically the "zoom" factor for the PDF.
  drawControlBar(page_no);
  pdf_file = file;
  current_page = page_no;
  loadPdf("/pdf/" + file, page_no);
}