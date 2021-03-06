var PdfViewer = function pdfViewerBuilder(scale, pdf_file, current_page) {
  PDFJS.disableWorker = true; //Not using web workers. Not disabling results in an error.
  self = this;
  
  this.setPdfInfo = function pdfSplit(filename) {
    self = this;
    if (filename.indexOf("/") > 0) {
      self.pdf_path = filename.substr(0, filename.lastIndexOf("/")+1);
      self.pdf_file = filename.substr(filename.lastIndexOf("/")+1), filename.length;
    } else {
      self.pdf_path = '';
      self.pdf_file = filename;
    }
  };
  
  this.setPdfInfo(pdf_file);
  this.current_page = current_page;
  this.scale = scale;
  
  this.loadFile = function loadPdf(file, page_num) {
    self = this;
    var promise = $.Deferred();
    this.setPdfInfo(pdf_file);
    var pdf = PDFJS.getDocument(file);
    pdf.then(function(result) {
      self.renderFile(result, page_num, file).then(function() {
        promise.resolve();
        this.current_page = page_num;
      });
    });
    return promise.promise();
  };
  
  this.renderFile = function renderPdf(pdf, page_no, filename) {
    self = this;
    var promise = $.Deferred();
    $prevButton = jQuery("#previous");
    $nextButton = jQuery("#next");
    if (page_no > 1) {
      $prevButton.removeClass("disabled");
      $prevButton.unbind("click");
      $prevButton.click(function() {self.loadFile(filename, page_no - 1)});
      $prevButton.css( 'cursor', 'pointer' );
    } else {
      $prevButton.unbind("click");
      $prevButton.addClass("disabled");
      $prevButton.css( 'cursor', 'default' );
    }
    if (page_no < pdf.numPages) {
      $nextButton.removeClass("disabled");
      $nextButton.unbind("click");
      $nextButton.click(function() {self.loadFile(filename, page_no + 1)});
      $nextButton.css( 'cursor', 'pointer' );
    } else {
      $nextButton.unbind("click");
      $nextButton.addClass("disabled");
      $nextButton.css( 'cursor', 'default' );
    }
    pdf.getPage(page_no).then(function(page) {
      self.renderPage(page).then(function() {
        promise.resolve();
        self.current_page = page_no;
      });
    });
    return promise.promise();
  };
  
  this.drawControls = function drawControlBar() {
    var $controlbarContainer = jQuery("#controlBar");
    var $prevButton = jQuery("<a id='previous'>&laquo;</a>");
    $controlbarContainer.append($prevButton);
    var $nextButton = jQuery("<a id='next'>&raquo;</a>");
    $controlbarContainer.append($nextButton);
  };

  this.renderPage = function renderPage(page) {
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
  };
  
  this.highlightLine = function highlightLine(line_no) {
    $( "div#line-" + line_no ).addClass("chosen");
  };
  
  this.removeHighlights = function removeAllHighlights() {
    $( ".chosen" ).removeClass("chosen");
  };
  
  this.highlightLines = function highlightLines(first_no, last_no) {
    self = this;
    last_no = parseInt(last_no);
    first_no = parseInt(first_no);
    if (last_no > first_no) {
      for (var line_no = first_no; line_no <= last_no; line_no++) {
        self.highlightLine(line_no);
      }
    } else {
      self.highlightLine(first_no);
    }
  };
  
  this.highlightPdfLine = function highlightPdfLine(file, page_no, line_no) {
    self = this;
    this.removeHighlights();
    if (this.pdf_path + this.pdf_file != file || page_no != this.current_page) {
      self.loadFile(file, page_no).then(function() {
        self.highlightLine(line_no);
      });
    } else {
      self.highlightLine(line_no);
    }
  };
  
  this.highlightPdfLines = function highlightPdfLines(file, page_no, start_line, end_line) {
    self = this;
    this.removeHighlights();
    if (this.pdf_path + this.pdf_file != file || page_no != this.current_page) {
      self.loadFile(file, page_no).then(function() {
        self.highlightLines(start_line, end_line);
      });
    }
    self.highlightLines(start_line, end_line);
  };

  this.render = function drawViewer() {
    this.drawControls();
    this.loadFile(this.pdf_path + this.pdf_file, this.current_page);
  };
};

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