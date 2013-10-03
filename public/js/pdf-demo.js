/* -*- Mode: Java; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set shiftwidth=2 tabstop=2 autoindent cindent expandtab: */

//
// See README for overview
//

'use strict';

//
// Separate the querystring from the location string 
// + return a dictionary of key/value pairs
//
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

//
// Fetch the PDF document from the URL using promises
//
var params = getUrlParams();
if (params["page"]) {
  var page_no = params["page"];
} else {
  var page_no = 1;
}
PDFJS.getDocument("/pdf/" + params["pdf"]).then(function(pdf) {
  // Using promise to fetch the page
  pdf.getPage(page_no).then(function(page) {
    var scale = 1.2;
    var viewport = page.getViewport(scale);

    //
    // Prepare canvas using PDF page dimensions
    //
    var canvas = document.getElementById('the-canvas');
    var context = canvas.getContext('2d');
    canvas.height = viewport.height;
    canvas.width = viewport.width;

    //
    // Render PDF page into canvas context
    //
    var renderContext = {
      canvasContext: context,
      viewport: viewport
    };
    page.render(renderContext);
  });
});