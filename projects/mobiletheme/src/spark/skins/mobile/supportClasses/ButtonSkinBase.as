////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2010 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.skins.mobile.supportClasses
{
    
    import flash.display.DisplayObject;
    import flash.display.GradientType;
    import flash.display.Graphics;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.text.TextLineMetrics;
    
    import mx.core.IFlexDisplayObject;
    import mx.core.ILayoutElement;
    import mx.core.IUITextField;
    import mx.core.UITextField;
    import mx.core.mx_internal;
    import mx.events.FlexEvent;
    import mx.managers.LayoutManager;
    import mx.states.SetProperty;
    import mx.states.State;
    import mx.utils.ColorUtil;
    
    import spark.components.Group;
    import spark.components.IconPlacement;
    import spark.components.supportClasses.ButtonBase;
    import spark.components.supportClasses.StyleableTextField;
    import spark.primitives.BitmapImage;
    import spark.skins.mobile.supportClasses.MobileSkin;
    
    use namespace mx_internal;
    
    /*    
    ISSUES:
    - should we support textAlign (if not, remove extra code)    
    */
    /**
     *  Actionscript based skin for mobile applications. The skin supports 
     *  icon and iconPlacement. It uses a couple of FXG classes to 
     *  implement the vector drawing.  
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5 
     *  @productversion Flex 4.5
     */
    public class ButtonSkinBase extends MobileSkin
    {
        //--------------------------------------------------------------------------
        //
        //  Constructor
        //
        //--------------------------------------------------------------------------
        
        public function ButtonSkinBase()
        {
            super();
            
            setStyle("textAlign", "center");
        }
        
        //--------------------------------------------------------------------------
        //
        //  Variables
        //
        //--------------------------------------------------------------------------
        
        /**
         *  iconDisplay skin part.
         */
        private var iconChanged:Boolean = false;
        private var iconInstance:Object;    // Can be either DisplayObject or BitmapImage
        private var iconHolder:Group;       // Needed when iconInstance is a BitmapImage
        private var _icon:Object;           // The currently set icon, can be Class, DisplayObject, URL
        
        /**
         *  labelDisplay skin part.
         */
        public var labelDisplay:StyleableTextField;
        
        public var labelDisplayShadow:StyleableTextField;      
        
        /**
         *  If true, then create the iconDisplay using the icon style
         * 
         *  @default true 
         */  
        protected var useIconStyle:Boolean = true;
        
        //--------------------------------------------------------------------------
        //
        //  Layout variables
        //
        //--------------------------------------------------------------------------
        
        protected var layoutBorderSize:uint;
        
        protected var layoutGap:int;
        
        protected var layoutPaddingLeft:int;
        
        protected var layoutPaddingRight:int;
        
        protected var layoutPaddingTop:int;
        
        protected var layoutPaddingBottom:int;
        
        //--------------------------------------------------------------------------
        //
        //  Overridden properties
        //
        //--------------------------------------------------------------------------
        
        /** 
         * @copy spark.skins.spark.ApplicationSkin#hostComponent
         */
        public var hostComponent:ButtonBase; // SkinnableComponent will popuplate
        
        //--------------------------------------------------------------------------
        //
        //  Overridden methods
        //
        //--------------------------------------------------------------------------
        
        /**
         *  @private 
         */ 
        override protected function commitCurrentState():void
        {
            super.commitCurrentState();
            
            commitDisabled(currentState.indexOf("disabled") >= 0);
        }
        
        protected function commitDisabled(isDisabled:Boolean):void
        {
            alpha = isDisabled ? 0.5 : 1;
        }
        
        /**
         *  @private 
         */ 
        override protected function createChildren():void
        {                   
            labelDisplay = StyleableTextField(createInFontContext(StyleableTextField));
            labelDisplay.styleName = this;
            labelDisplay.addEventListener(FlexEvent.VALUE_COMMIT, labelDisplay_valueCommitHandler);
            
            labelDisplayShadow = StyleableTextField(createInFontContext(StyleableTextField));
            labelDisplayShadow.styleName = this;
            labelDisplayShadow.colorName = "textShadowColor";
            
            addChild(labelDisplayShadow);
            addChild(labelDisplay);
        }
        
        /**
         *  @private 
         */ 
        override public function styleChanged(styleProp:String):void 
        {    
            var allStyles:Boolean = !styleProp || styleProp == "styleName";
            
            if (allStyles || styleProp == "iconPlacement")
            {
                invalidateSize();
                invalidateDisplayList();
            }
            
            if (useIconStyle && (allStyles || styleProp == "icon"))
            {
                iconChanged = true;
                invalidateProperties();
            }
            
            if (styleProp == "textShadowAlpha")
            {
                invalidateDisplayList();
            }
            
            super.styleChanged(styleProp);
        }
        
        /**
         *  @private 
         */ 
        override protected function commitProperties():void
        {
            super.commitProperties();
            
            if (iconChanged)
            {
                iconChanged = false;
                if (useIconStyle)
                    setIcon(getStyle("icon"));
            }
        }
        
        /**
         *  @private 
         */ 
        override protected function measure():void
        {        
            super.measure();
            
            var iconPlacement:String = getStyle("iconPlacement");
            
            var textWidth:Number = 0;
            var textHeight:Number = 0;
            
            // reset text if it was truncated before.
            if (hostComponent && labelDisplay.isTruncated)
                labelDisplay.text = hostComponent.label;
            labelDisplay.commitStyles();
            
            if (hostComponent && hostComponent.label != "")
            {
                // FIXME (jasonsj): was previously textWidth + UITextField.TEXT_WIDTH_PADDING + 1;
                //                  +1 originates from MX Button without explaination
                var textSize:Point = labelDisplay.measuredTextSize;
                textWidth = textSize.x + 1;
                textHeight = textSize.y;
            }
            else
            {
                textHeight = measureText("Wj").height + UITextField.TEXT_HEIGHT_PADDING;
            }
            
            var iconDisplay:DisplayObject = getIconDisplay();
            var iconWidth:Number = iconDisplay ? iconDisplay.width : 0;
            var iconHeight:Number = iconDisplay ? iconDisplay.height : 0;
            var w:Number = 0;
            var h:Number = 0;
            
            if (iconDisplay is ILayoutElement)
            {
                iconWidth = ILayoutElement(iconDisplay).getPreferredBoundsWidth(false);
                iconHeight = ILayoutElement(iconDisplay).getPreferredBoundsHeight(false);
            }
            
            if (iconPlacement == IconPlacement.LEFT ||
                iconPlacement == IconPlacement.RIGHT)
            {
                w = textWidth + iconWidth;
                if (textWidth && iconWidth)
                    w += layoutGap;
                h = Math.max(textHeight, iconHeight);
            }
            else
            {
                w = Math.max(textWidth, iconWidth);
                h = textHeight + iconHeight;
                if (textHeight && iconHeight)
                    h += layoutGap;
            }
            
            w += layoutPaddingLeft + layoutPaddingRight;
            h += layoutPaddingTop + layoutPaddingBottom;
            
            measuredWidth = Math.max(w, layoutMeasuredWidth);
            measuredMinHeight = measuredHeight = Math.max(h, layoutMeasuredHeight);
            measuredMinWidth = iconWidth + layoutPaddingLeft + layoutPaddingRight;
        }
        
        /**
         *  @private 
         */ 
        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            var labelWidth:Number = 0;
            var labelHeight:Number = 0;
            
            var labelX:Number = 0;
            var labelY:Number = 0;
            
            var iconWidth:Number = 0;
            var iconHeight:Number = 0;
            
            var iconX:Number = 0;
            var iconY:Number = 0;
            
            var horizontalGap:Number = 0;
            var verticalGap:Number = 0;
            
            var iconPlacement:String = getStyle("iconPlacement");
            
            var textWidth:Number = 0;
            var textHeight:Number = 0;
            var textDescent:Number = 0;
            
            // reset text if it was truncated before.
            if (hostComponent && labelDisplay.isTruncated)
                labelDisplay.text = hostComponent.label;
            labelDisplay.commitStyles();
            
            if (hostComponent && hostComponent.label != "")
            {
                // FIXME (jasonsj): was previously textWidth + UITextField.TEXT_WIDTH_PADDING + 1;
                //                  +1 originates from MX Button without explaination
                var textSize:Point = labelDisplay.measuredTextSize;
                textWidth = textSize.x + 1;
                textHeight = textSize.y;
                textDescent = labelDisplay.getLineMetrics(0).descent;
            }
            else
            {
                var metrics:TextLineMetrics = measureText("Wj");
                textHeight = metrics.height + UITextField.TEXT_HEIGHT_PADDING;
                textDescent = metrics.descent;
            }
            
            var textAlign:String = "center"; // getStyle("textAlign");
            // Map new Spark values that might be set in a selector
            // affecting both Halo and Spark components.
            /*if (textAlign == "start") 
            textAlign = TextFormatAlign.LEFT;
            else if (textAlign == "end")
            textAlign = TextFormatAlign.RIGHT;*/
            
            var viewWidth:Number = unscaledWidth;
            var viewHeight:Number = unscaledHeight;
            
            var iconDisplay:DisplayObject = getIconDisplay();
            if (iconDisplay)
            {
                if (iconDisplay is ILayoutElement)
                {
                    iconWidth = ILayoutElement(iconDisplay).getPreferredBoundsWidth();
                    iconHeight = ILayoutElement(iconDisplay).getPreferredBoundsHeight();
                }
                else
                {
                    iconWidth = iconDisplay.width;
                    iconHeight = iconDisplay.height;
                }
            }
            
            if (iconPlacement == IconPlacement.LEFT ||
                iconPlacement == IconPlacement.RIGHT)
            {
                horizontalGap = layoutGap;
                
                if (iconWidth == 0 || textWidth == 0)
                    horizontalGap = 0;
                
                if (textWidth > 0)
                {
                    labelWidth = 
                        Math.max(Math.min(viewWidth - iconWidth - horizontalGap -
                            layoutPaddingLeft - layoutPaddingRight, textWidth), 0);
                }
                else
                {
                    labelWidth = 0;
                }
                labelHeight = Math.min(viewHeight, textHeight);
                
                if (textAlign == "left")
                {
                    labelX += layoutPaddingLeft;
                }
                else if (textAlign == "right")
                {
                    labelX += (viewWidth - labelWidth - iconWidth - 
                        horizontalGap - layoutPaddingRight);
                }
                else // "center" -- default value
                {
                    labelX += ((viewWidth - labelWidth - iconWidth - 
                        horizontalGap - layoutPaddingLeft - layoutPaddingRight) / 2) + layoutPaddingLeft;
                }
                
                if (iconPlacement == IconPlacement.LEFT)
                {
                    labelX += iconWidth + horizontalGap;
                    iconX = labelX - (iconWidth + horizontalGap);
                }
                else
                {
                    iconX  = labelX + labelWidth + horizontalGap; 
                }
                
                // FIXME (jasonsj): enforcement of layoutPaddingTop && layoutPaddingBottom for text
                iconY  = ((viewHeight - iconHeight - layoutPaddingTop - layoutPaddingBottom) / 2) + layoutPaddingTop;
                labelY = ((viewHeight - labelHeight + textDescent - StyleableTextField.TEXT_HEIGHT_PADDING) / 2);
            }
            else
            {
                verticalGap = layoutGap;
                
                if (iconHeight == 0 || !hostComponent || hostComponent.label == "")
                    verticalGap = 0;
                
                if (textWidth > 0)
                {
                    labelWidth = Math.max(viewWidth - layoutPaddingLeft - layoutPaddingRight, 0);
                    labelHeight =
                        Math.min(viewHeight - iconHeight - layoutPaddingTop - layoutPaddingBottom - verticalGap, textHeight);
                }
                else
                {
                    labelWidth = 0;
                    labelHeight = 0;
                }
                
                labelX = layoutPaddingLeft;
                
                if (textAlign == "left")
                {
                    iconX += layoutPaddingLeft;
                }
                else if (textAlign == "right")
                {
                    iconX += Math.max(viewWidth - iconWidth - layoutPaddingRight, layoutPaddingLeft);
                }
                else
                {
                    iconX += ((viewWidth - iconWidth - layoutPaddingLeft - layoutPaddingRight) / 2) + layoutPaddingLeft;
                }
                
                if (iconPlacement == IconPlacement.BOTTOM)
                {
                    labelY += ((viewHeight - labelHeight - iconHeight - 
                        layoutPaddingTop - layoutPaddingBottom - verticalGap) / 2) + layoutPaddingTop;
                    iconY += labelY + labelHeight + verticalGap;
                }
                else
                {
                    iconY += ((viewHeight - labelHeight - iconHeight - 
                        layoutPaddingTop - layoutPaddingBottom - verticalGap) / 2) + layoutPaddingTop;
                    labelY += iconY + iconHeight + verticalGap;
                }
            }
            
            labelX = Math.max(0, Math.round(labelX));
            labelY = Math.max(0, Math.round(labelY));
            
            labelDisplay.commitStyles();
            setElementSize(labelDisplay, labelWidth, labelHeight);
            setElementPosition(labelDisplay, labelX, labelY); 
            
            if (textWidth > labelWidth)
            {
                labelDisplay.truncateToFit();
            }
            
            labelDisplayShadow.alpha = getStyle("textShadowAlpha");
            labelDisplayShadow.commitStyles();
            
            // FIXME (jasonsj): this resize causes scaling issues at 1.5x and 2x
            // artifacts show below ActionBar buttons
            setElementSize(labelDisplayShadow, labelWidth, labelHeight);
            setElementPosition(labelDisplayShadow, labelX, labelY + 1); 
            
            // if labelDisplay is truncated, then push it down here as well.
            // otherwise, it would have gotten pushed in the labelDisplay_valueCommitHandler()
            if (labelDisplay.isTruncated)
                labelDisplayShadow.text = labelDisplay.text;
            
            if (iconDisplay)
            {
                setElementSize(iconDisplay, iconWidth, iconHeight);
                setElementPosition(iconDisplay, Math.max(0, Math.round(iconX)), Math.max(0, Math.round(iconY))); 
            }
            
            // draw chromeColor after parts have been positioned
            super.updateDisplayList(unscaledWidth, unscaledHeight);
        }
        
        //--------------------------------------------------------------------------
        //
        //  Class methods
        //
        //--------------------------------------------------------------------------
        
        /**
         *  The current skin part that displays the icon.
         *  If the icon is a Class, then the iconDisplay is an instance of that class.
         *  If the icon is a DisplayObject instance, then the iconDisplay is that instance.
         *  If the icon is URL, then iconDisplay is the Group that holds the BitmapImage with that URL.
         * 
         *  @see #setIcon
         *  @see #useIconStyle
         */
        protected function getIconDisplay():DisplayObject
        {
            return iconHolder ? iconHolder : iconInstance as DisplayObject;
        }
        
        /**
         *  Sets the current icon for the iconDisplay skin part.
         *  The iconDisplay skin part is created/set-up on demand.
         *
         *  @see #getIconDisplay
         *  @see #useIconStyle
         */
        protected function setIcon(icon:Object):void
        {
            if (_icon == icon)
                return;
            _icon = icon;
            
            // Clean-up the iconInstance
            if (iconInstance)
            {
                if (iconHolder)
                    iconHolder.removeAllElements();
                else
                    this.removeChild(iconInstance as DisplayObject);
            }
            iconInstance = null;
            
            // Set-up the iconHolder
            var needsHolder:Boolean = icon && !(icon is Class) && !(icon is DisplayObject);
            if (needsHolder && !iconHolder)
            {
                iconHolder = new Group();
                this.addChildAt(iconHolder, 0);
            }
            else if (!needsHolder && iconHolder)
            {
                this.removeChild(iconHolder);
                iconHolder = null;
            }
            
            // Set-up the icon
            if (icon)
            {
                if (needsHolder)
                {
                    iconInstance = new BitmapImage();
                    iconInstance.source = icon;
                    iconHolder.addElementAt(iconInstance as BitmapImage, 0);
                }
                else
                {
                    if (icon is Class)
                        iconInstance = new (Class(icon))();
                    else
                        iconInstance = icon;
                    
                    addChildAt(iconInstance as DisplayObject, 0);
                }
            }
            
            // explicitly invalidate, since addChild/removeChild don't invalidate for us
            invalidateSize();
            invalidateDisplayList();
        }
        
        //--------------------------------------------------------------------------
        //
        //  Event Handlers
        //
        //--------------------------------------------------------------------------
        
        /**
         *  @private 
         */
        private function labelDisplay_valueCommitHandler(event:FlexEvent):void 
        {
            labelDisplayShadow.text = labelDisplay.text;
            invalidateSize();
            invalidateDisplayList();
        }
    }
}