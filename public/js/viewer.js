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
  var pdf = PDFJS.getDocument(file);
  pdf.then(function(result) {
    renderPdf(result, page_num, file);
  });
}

function renderPdf(pdf, page_no, filename){
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
  pdf.getPage(page_no).then(renderPage);
}

function drawControlBar(currentPage) {
  var $controlbarContainer = jQuery("#controlBar");
  var $prevButton = jQuery("<a id='previous' href='#'>&laquo;</a>");
  $controlbarContainer.append($prevButton);
  var $nextButton = jQuery("<a id='next' href='#'>&raquo;</a>");
  $controlbarContainer.append($nextButton);
}

function renderPage(page) {
  var viewport = page.getViewport(scale);
  var $canvas = jQuery("<canvas></canvas>");
  
  //Set the canvas height and width to the height and width of the viewport
  var canvas = $canvas.get(0);
  var context = canvas.getContext("2d");
  canvas.height = viewport.height;
  canvas.width = viewport.width;
  var $controlbarContainer = jQuery("#controlBar");
  $controlbarContainer.css("width", canvas.width + "px");
  
  var $pdfContainer = jQuery("#pdfContainer");
  
  //Clear previous textLayers
  $pdfContainer.empty();
  
  //Append the canvas to the pdf container div
  $pdfContainer.css("height", canvas.height + "px").css("width", canvas.width + "px");
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
      
      page.render(renderContext);
  });
}


$(function(){
  PDFJS.disableWorker = true; //Not using web workers. Not disabling results in an error.
  scale = 1.2; //Set this to whatever you want. This is basically the "zoom" factor for the PDF.
  
  var params = getUrlParams();
  if (params["page"]) {
    var page_no = parseInt(params["page"]);
  } else {
    var page_no = 1;
  }
  
  drawControlBar(page_no);
  loadPdf("/pdf/" + params["pdf"], page_no);
});