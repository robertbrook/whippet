/**
 * Code extracted from pdf.js' viewer.js file. This contains code that is relevant to building the text overlays. I
 * have removed dependencies on viewer.js and viewer.html.
 *
 *   -- Vivin Suresh Paliath (http://vivin.net)
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
        var line = 0;
        var $lineDiv = "";
        
        // No point in rendering so many divs as it'd make the browser unusable
        // even after the divs are rendered
        var MAX_TEXT_DIVS_TO_RENDER = 100000;
        if (textDivs.length > MAX_TEXT_DIVS_TO_RENDER)
            return;
        
        for (var i = 0, ii = textDivs.length; i < ii; i++) {
            var textDiv = textDivs[i];
            
            if (textDiv.data("isWhitespace") == true && 
                line < 1 ||(i > 0 && textDivs[i-1].data("isWhiteSpace") == true)) 
            {
                continue;
            } else {
              textDiv.text(" ");
            }
            //textLayerFrag.appendChild(textDiv);
            if ($lineDiv != "" && textDivs[i].css("top") == textDivs[i-1].css("top")) {
              textDiv.css("width", textDiv.data("canvasWidth") + "px");
              tempDiv = textDiv.clone();
              tempDiv.css("top", 0);
              tempDiv.css("position", "absolute");
              $lineDiv.append(tempDiv);
            }
            
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
                
                if (i == 0 || textDivs[i].css("top") != textDivs[i-1].css("top")) {
                  if ($lineDiv != "") {
                    $lineDiv.appendTo(textLayerDiv);
                  }
                  $lineDiv = jQuery("<div></div>");
                  $lineDiv.addClass("textLine");
                  $lineDiv.css("position", "absolute");
                  $lineDiv.css("top", textDiv.css("top"));
                  textDiv.css("width", textDiv.data("canvasWidth") + "px");
                  $lineDiv.css("width", "100%");
                  if (line == 0 && parseFloat(textDiv.css("top").replace("px", "")) > 800.0) {
                    $lineDiv.attr("id", "line-footer");
                  } else {
                    line +=1;
                    $lineDiv.attr("id", "line-" + line);
                  }
                  tempDiv = textDiv.clone();
                  tempDiv.css("top", 0);
                  $lineDiv.append(tempDiv);
                }
            }
        }
        $lineDiv.appendTo(textLayerDiv);
        
        this.renderingDone = true;
        
        textLayerDiv.appendChild(textLayerFrag);
    };
    
    this.setupRenderLayoutTimer = function textLayerSetupRenderLayoutTimer() {
        // Schedule renderLayout() if user has been scrolling, otherwise
        // run it right away
        var RENDER_DELAY = 200; // in ms
        var self = this;
        //0 was originally PDFView.lastScroll
        if (Date.now() - 0 > RENDER_DELAY) {
            // Render right away
            this.renderLayer();
        } else {
            // Schedule
            if (this.renderTimer)
                clearTimeout(this.renderTimer);
            this.renderTimer = setTimeout(function () {
                self.setupRenderLayoutTimer();
            }, RENDER_DELAY);
        }
    };
    
    this.appendText = function textLayerBuilderAppendText(geom) {
        var $textDiv = jQuery("<div></div>");
        
        // vScale and hScale already contain the scaling to pixel units
        var fontHeight = geom.fontSize * Math.abs(geom.vScale);
        $textDiv.data("canvasWidth", geom.canvasWidth * geom.hScale);
        $textDiv.data("fontName", geom.fontName);
        
        $textDiv.css("font-size", fontHeight + 'px');
        $textDiv.css("font-family", geom.fontFamily);
        $textDiv.css("margin-left", geom.x + 'px');
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
                textDiv.data("isWhitespace", true);
                continue;
            }
            
            textDiv.text(bidiText.str);
            // bidiText.dir may be 'ttb' for vertical texts.
            textDiv.attr("dir", bidiText.dir === 'rtl' ? 'rtl' : 'ltr');
        }
        
        this.setupRenderLayoutTimer();
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