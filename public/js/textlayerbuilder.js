/**
 * Adapted from Vivin Suresh Paliath's (http://vivin.net) textlayerbuilder.js
 * Please assume all the errors are mine & all the nice documentation Vivin's!
 *
 *   -- Liz Conlan
 */

var CustomStyle = (function CustomStyleClosure() {

  // As noted on: http://www.zachstronaut.com/posts/2009/02/17/
  //              animate-css-transforms-firefox-webkit.html
  // in some versions of IE9 it is critical that ms appear in this list
  // before Moz
  var prefixes = ['ms', 'Moz', 'Webkit', 'O'];
  var _cache = { };
  
  function CustomStyle() {
  }
    
  CustomStyle.getProp = function get(propName, element) {
    // check cache only when no element is given
    if (arguments.length == 1 && typeof _cache[propName] == 'string') {
      return _cache[propName];
    }
      
    element = element || document.documentElement;
    var style = element.style, prefixed, uPropName;
      
    // test standard property first
    if (typeof style[propName] == 'string') {
      return (_cache[propName] = propName);
    }
    
    // capitalize
    uPropName = propName.charAt(0).toUpperCase() + propName.slice(1);
    
    // test vendor specific properties
    for (var i = 0, l = prefixes.length; i < l; i++) {
      prefixed = prefixes[i] + uPropName;
      if (typeof style[prefixed] == 'string') {
        return (_cache[propName] = prefixed);
      }
    }
    
    //if all fails then set to undefined
    return (_cache[propName] = 'undefined');
  };
  
  CustomStyle.setProp = function set(propName, element, str) {
    var prop = this.getProp(propName);
    if (prop != 'undefined')
      element.css(prop, str);
  };
  
  return CustomStyle;
})();

var TextLayerBuilder = function textLayerBuilder(textLayerDiv, pageIdx) {
  var textLayerFrag = document.createDocumentFragment();
  
  this.textLayerDiv = textLayerDiv;
  this.layoutDone = false;
  this.divContentDone = false;
  this.pageIdx = pageIdx;
  this.matches = [];
    
  this.beginLayout = function textLayerBuilderBeginLayout() {
    this.textDivs = [];
    this.renderingDone = false;
  };
  
  this.endLayout = function textLayerBuilderEndLayout() {
    this.layoutDone = true;
    this.insertDivContent();
  };
    
  this.renderLayer = function textLayerBuilderRenderLayer() {
    var textDivs = this.textDivs;
    var bidiTexts = this.textContent.bidiTexts;
    var textLayerDiv = this.textLayerDiv;
    var canvas = document.createElement('canvas');
    var ctx = canvas.getContext('2d');
    var lineDivs = [];
    var lines = []
    var currentText = "";
    var lineText = "";
    var line = 0;
    var days = 0;
    var $lineDiv = "";
    
    for (var i = 0, ii = textDivs.length; i < ii; i++) {
      var textDiv = textDivs[i];
      
      if (textDiv.data("isWhiteSpace") == true) {
        currentText = " ";
      } else {
        currentText = textDiv.text();
      }
      
      textDiv.text(" ");
      ctx.font = textDiv.css("font-size") + ' ' + textDiv.css("font-family");
      var width = ctx.measureText(textDiv.textContent).width;
      
      if (width > 0) {
        var textScale = textDiv.data("canvasWidth") / width;
        
        var transform = 'scale(' + textScale + ', 1)';
        if (bidiTexts[i].dir === 'ttb') {
          transform = 'rotate(90deg) ' + transform;
        }
        CustomStyle.setProp('transform', textDiv, transform);
        CustomStyle.setProp('transformOrigin', textDiv, '0% 0%');
        
        if (i > 0 && textDivs[i].css("top") != textDivs[i-1].css("top")) {
          lines.push(lineText);
          lineText = currentText;
          if ($lineDiv != "") {
            lineText = currentText;
            $lineDiv.appendTo(textLayerDiv);
          }
          $lineDiv = jQuery("<div></div>");
          $lineDiv.addClass("textLine");
          $lineDiv.css("position", "absolute");
          $lineDiv.css("top", textDivs[i-1].css("top"));
          $lineDiv.css("width", "100%");
          if (line < 1 && parseFloat(textDivs[i-1].css("top").replace("px", "")) > 500.0) {
            $lineDiv.attr("id", "line-footer");
          } else {
            if (/\S/.test(lines[lines.length-1])) {
              line += 1;
              if (/[A-Z]+DAY \d+ [A-Z]+ \d\d\d\d/.test(lines[lines.length-1])) {
                days += 1;
                if (days > 1)
                  line +=1;
              }
              $lineDiv.attr("id", "line-" + line);
            } else {
              if (lines.length > 1 && /\S/.test(lines[lines.length-2])) {
                line += 1;
                $lineDiv.attr("id", "line-" + line);
              }
            }
          }
          tempDiv = textDiv.clone();
          tempDiv.css("top", 0);
          $lineDiv.append(tempDiv);
        } else {
          lineText += currentText;
        }
      }
    }
    //alert(lines);
    $lineDiv.appendTo(textLayerDiv);
    
    this.renderingDone = true;
    
    textLayerDiv.appendChild(textLayerFrag);
  };
    
  this.appendText = function textLayerBuilderAppendText(geom) {
    var $textDiv = jQuery("<div></div>");
    
    // vScale and hScale already contain the scaling to pixel units
    var fontHeight = geom.fontSize * Math.abs(geom.vScale);
    $textDiv.data("fontName", geom.fontName);
    
    $textDiv.css("font-size", fontHeight + 'px');
    $textDiv.css("font-family", geom.fontFamily);
    $textDiv.css("top", (geom.y - fontHeight) + 'px');
    
    // The content of the div is set in the `setTextContent` function.
    
    this.textDivs.push($textDiv);
  };
    
  this.insertDivContent = function textLayerUpdateTextContent() {
    // Only set the content of the divs once layout has finished, the content
    // for the divs is available and content is not yet set on the divs.
    if (!this.layoutDone || this.divContentDone || !this.textContent)
      return;
      
    this.divContentDone = true;
      
    var textDivs = this.textDivs;
    var bidiTexts = this.textContent.bidiTexts;
    
    for (var i = 0; i < bidiTexts.length; i++) {
      var bidiText = bidiTexts[i];
      var textDiv = textDivs[i];
      if (!/\S/.test(bidiText.str)) {
        textDiv.data("isWhiteSpace", true);
        continue;
      }
      
      textDiv.text(bidiText.str);
      // bidiText.dir may be 'ttb' for vertical texts.
      textDiv.attr("dir", bidiText.dir === 'rtl' ? 'rtl' : 'ltr');
    }
    
    this.renderLayer();
  };
    
  this.setTextContent = function textLayerBuilderSetTextContent(textContent) {
    this.textContent = textContent;
    this.insertDivContent();
  };
};

/**
 * Returns scale factor for the canvas. It makes sense for the HiDPI displays.
 * @return {Object} The object with horizontal (sx) and vertical (sy)
 scales. The scaled property is set to false if scaling is
 not required, true otherwise.
 */
function getOutputScale() {
  var pixelRatio = 'devicePixelRatio' in window ? window.devicePixelRatio : 1;
  return {
    sx: pixelRatio,
    sy: pixelRatio,
    scaled: pixelRatio != 1
  };
}