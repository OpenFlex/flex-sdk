////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.components.supportClasses
{
import __AS3__.vec.Vector;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.ui.Keyboard;

import mx.core.IDataRenderer;
import mx.core.IFactory;
import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.events.FlexEvent;
import mx.formatters.NumberFormatter;
import mx.managers.IFocusManagerComponent;

import spark.effects.animation.MotionPath;
import spark.effects.animation.SimpleMotionPath;
import spark.effects.animation.Animation;
import spark.effects.easing.Sine;
import spark.events.TrackBaseEvent;

include "../../styles/metadata/BasicInheritingTextStyles.as"

/**
 *  @copy spark.components.supportClasses.GroupBase#focusColor
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */ 
[Style(name="focusColor", type="uint", format="Color", inherit="yes", theme="spark")]

/**
 *  When <code>true</code>, the thumb's value is
 *  committed as it is dragged along the track instead
 *  of when the thumb button is released.
 *  
 *  @default false
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Style(name="liveDragging", type="Boolean", inherit="no")]

/**
 *  The Slider class lets users select a value by moving a slider thumb between 
 *  the end points of the slider track. 
 *  The current value of the slider is determined by the relative location of 
 *  the thumb between the end points of the slider, 
 *  corresponding to the slider's minimum and maximum values.
 *
 *  The Slider class is a base class for HSlider and VSlider.
 *
 *  @mxml
 *
 *  <p>The <code>&lt;Slider&gt;</code> tag inherits all of the tag 
 *  attributes of its superclass and adds the following tag attributes:</p>
 *
 *  <pre>
 *  &lt;Slider
 *    <strong>Properties</strong>
 *    dataTipFormatFunction="20"
 *    dataTipPrecision="2"
 *    showDataTip="true"
 *
 *    <strong>Styles</strong>
 *    alignmentBaseline="USE_DOMINANT_BASELINE"
 *    baselineShift="0.0"
 *    breakOpportunity="AUTO"
 *    cffHinting="HORIZONTAL_STEM"
 *    color="0"
 *    digitCase="DEFAULT"
 *    digitWidth="DEFAULT"
 *    direction="LTR"
 *    dominantBaseline="AUTO"
 *    focusColor
 *    fontFamily="Times New Roman"
 *    fontLookup="DEVICE"
 *    fontSize="12"
 *    fontStyle="NORMAL"
 *    fontWeight="NORMAL"
 *    justificationRule="AUTO"
 *    justificationStyle="AUTO"
 *    kerning="AUTO"
 *    ligatureLevel="COMMON"
 *    lineHeight="120%"
 *    lineThrough="false"
 *    liveDragging="false"
 *    local="en"
 *    renderingMode="CFF"
 *    textAlign="START"
 *    textAlignLast="START"
 *    textAlpha="1"
 *    textDecoration="NONE"
 *    textJustify="INTER_WORD"
 *    trackingLeft="0"
 *    trackingRight="0"
 *    typographicCase="DEFAULT"
 *  /&gt;
 *  </pre> 
 *  
 *  @see spark.components.HSlider
 *  @see spark.components.VSlider
 *
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class Slider extends TrackBase implements IFocusManagerComponent
{
    include "../../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function Slider():void
    {
        super();
    }

	//--------------------------------------------------------------------------
    //
    //  Skin Parts
    //
    //--------------------------------------------------------------------------

    [SkinPart(required="false", type="mx.core.IDataRenderer")]
    
    /**
     *  A skin part that defines a dataTip that displays a formatted version of 
     *  the current value. The dataTip appears while the thumb is being dragged.
     *  This is a dynamic skin part and must be of type IFactory.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var dataTip:IFactory; 

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

	private var dataFormatter:NumberFormatter;

    private var animator:Animation = null;
    
    private var dataTipInitialPosition:Point;
    
    private var dataTipInstance:IDataRenderer;
    //--------------------------------------------------------------------------
    //
    // Properties
    //
    //-------------------------------------------------------------------------- 	

	//--------------------------------- 
    // dataTipformatFunction
    //---------------------------------

	private var _dataTipFormatFunction:Function;
	
	 /**
     *  Callback function that formats the data tip text.
     *  The function takes a single Number as an argument
     *  and returns a formatted String.
     *
     *  <p>The function has the following signature:</p>
     *  <pre>
     *  funcName(value:Number):Object
     *  </pre>
     *
     *  <p>The following example prefixes the data tip text with a dollar sign and 
     *  formats the text using the <code>dataTipPrecision</code> 
     *  of a Slider Control named 'slide': </p>
     *
     *  <pre>
     *  import mx.formatters.NumberBase;
     *  function myDataTipFormatter(value:Number):Object { 
     *      var dataFormatter:NumberBase = new NumberBase(".", ",", ".", ""); 
     *      return   "$ " + dataFormatter.formatPrecision(String(value), slide.dataTipPrecision); 
     *  }
     *  </pre>
     *
     *  @default undefined   
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
	public function set dataTipFormatFunction(value:Function):void
	{
		_dataTipFormatFunction = value;
	}
	
	public function get dataTipFormatFunction():Function
	{
		return _dataTipFormatFunction;
	}
	
	//--------------------------------- 
    // dataTipPrecision
    //---------------------------------
    /**
	 *  Number of decimal places to use for the data tip text.
	 *  A value of 0 means to round all values to an integer.
	 *  This value is ignored if <code>dataTipFormatFunction</code> is defined.
	 * 
	 *  @default 2
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
    public var dataTipPrecision:int = 2;
    
    //--------------------------------- 
    // showDataTip
    //---------------------------------
    
    /**
     *  If set to <code>true</code>, shows a data tip during user interaction
     *  containing the current value of the slider. In addition, the skinPart
     *  <code>dataTipFactory</code> must be defined in the skin in order to 
     *  display a data tip. 
     *  @default true
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var showDataTip:Boolean = true;

    //----------------------------------
    //  pendingValue
    //----------------------------------
    
    /**
     *  @private
     */
    private var _pendingValue:Number = 0;
    
    /**
     *  The value the slider will have when the mouse button is released.
     * 
     *  <p>If the <code>liveDragging</code> style is false, then the slider's value is only set
     *  when the mouse button is released. The value is not updated while the slider thumb is
     *  being dragged.</p>
     * 
     *  <p>This property is updated when the slider thumb moves, even if 
     *  <code>liveDragging</code> is false.</p>
     *  
     *  @default 0
     *  @return The value implied by the thumb position. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function get pendingValue():Number
    {
        return _pendingValue;
    }
    
    /**
     *  @private
     */
    protected function set pendingValue(value:Number):void
    {
        if (value == _pendingValue)
            return;
        _pendingValue = value;
        invalidateDisplayList();
    }
    
    //--------------------------------------------------------------------------
    //
    // Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     *  Keep the pendingValue in sync with the actual value so that updateSkinDisplayList()
     *  overrides can just use pendingValue.
     */
    override protected function setValue(value:Number):void
    {
        _pendingValue = value;
        super.setValue(value);
    }

    /**
     *  @private
     */  
    override protected function partAdded(partName:String, instance:Object):void
    {
        super.partAdded(partName, instance);
        
        // Prevent focus on our children so that focus remains with the Slider
        if (instance == thumb)
            thumb.focusEnabled = false;
        else if (instance == track)
            track.focusEnabled = false;
    }
    
    /**
     *  @private
     */
    override public function drawFocus(isFocused:Boolean):void
    {
        // if there's a thumb, just draw focus on the thumb; 
        // otherwise, draw it on the whole component
        if (thumb)
        {
            thumb.mx_internal::drawFocusAnyway = true;
            thumb.drawFocus(isFocused);
        }
        else
        {
            super.drawFocus(isFocused);
        }
    }
    
    /**
     *  @private
     *  Returns a formatted version of the value
     */
    private function formatDataTipText(value:Number):Object
    {
    	var formattedValue:Object;
    		
		if (dataTipFormatFunction != null)
		{
			formattedValue = dataTipFormatFunction(value); 
		}
		else
		{
			if (dataFormatter == null)
				dataFormatter = new NumberFormatter();
				
			dataFormatter.precision = dataTipPrecision;
			
			formattedValue = dataFormatter.format(value);	
		}
		
		return formattedValue;
    }
  
   
    /**
     *  Used to position the data tip when it is visible. Subclasses must implement
     *  this function. 
     *  
     *  @param dataTipInstance The <code>dataTip</code> instance to update and position
     *  @param initialPosition The initial position of the <code>dataTip</code> in the skin
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function updateDataTip(dataTipInstance:IDataRenderer, initialPosition:Point):void
    {
		// Override in the subclasses
    }

    //--------------------------------------------------------------------------
    // 
    // Event Handlers
    //
    //--------------------------------------------------------------------------

    //---------------------------------
    // Thumb dragging handlers
    //---------------------------------
    /**
     *  @private
     *  Location of the mouse down event on the thumb, relative to the thumb's origin.
     *  Used to update the value property when the mouse is dragged. 
     */
    private var clickOffset:Point;  
        
    /**
     *  @private
     */
    override protected function thumb_mouseDownHandler(event:MouseEvent):void
    {
        super.thumb_mouseDownHandler(event);
        clickOffset = thumb.globalToLocal(new Point(event.stageX, event.stageY));
        
        // Popup a dataTip only if we have a SkinPart and the boolean flag is true
        if (dataTip && showDataTip && enabled)
        {
	        dataTipInstance = IDataRenderer(createDynamicPartInstance("dataTip"));
	        systemManager.toolTipChildren.addChild(DisplayObject(dataTipInstance));
	        
	        dataTipInstance.data = formatDataTipText(value);
	        
	        // Force the dataTip to render so that we have the correct size since
	        // updateDataTip might need the size
	        var tipAsUIComponent:UIComponent = dataTipInstance as UIComponent; 
	        if (tipAsUIComponent)
	        {
	        	tipAsUIComponent.validateNow();
	        	tipAsUIComponent.setActualSize(tipAsUIComponent.getExplicitOrMeasuredWidth(),
	        								   tipAsUIComponent.getExplicitOrMeasuredHeight());
	        }
	        
	        dataTipInitialPosition = new Point(DisplayObject(dataTipInstance).x, 
	        									DisplayObject(dataTipInstance).y);   
	        updateDataTip(dataTipInstance, dataTipInitialPosition);
        }
    }

    /**
     *  @private
     */
    override protected function system_mouseMoveHandler(event:MouseEvent):void
    {      
        var p:Point = track.globalToLocal(new Point(event.stageX, event.stageY));
        var newValue:Number = pointToValue(p.x - clickOffset.x, p.y - clickOffset.y);
        newValue = nearestValidValue(newValue, snapInterval);
        
        if (newValue != pendingValue)
        {
            dispatchEvent(new TrackBaseEvent(TrackBaseEvent.THUMB_DRAG));
            if (getStyle("liveDragging") === true)
            {
                setValue(newValue); 
                dispatchEvent(new Event(Event.CHANGE));   
            }
            else
                pendingValue = newValue;
        }
                  
        if (dataTipInstance && showDataTip)
        { 
	        dataTipInstance.data = formatDataTipText(pendingValue);
	        
	        // Force the dataTip to render so that we have the correct size since
	        // updateDataTip might need the size
	        var tipAsUIComponent:UIComponent = dataTipInstance as UIComponent; 
	        if (tipAsUIComponent)
	        {
	        	tipAsUIComponent.validateNow();
	        	tipAsUIComponent.setActualSize(tipAsUIComponent.getExplicitOrMeasuredWidth(),tipAsUIComponent.getExplicitOrMeasuredHeight());
	        }
	        
			updateDataTip(dataTipInstance, dataTipInitialPosition);
        }
        
        event.updateAfterEvent();
    }
    
    /**
     *  @private
     */
    override protected function system_mouseUpHandler(event:MouseEvent):void
    {
        if ((getStyle("liveDragging") === false) && (value != pendingValue))
        {
            setValue(pendingValue);
            dispatchEvent(new Event(Event.CHANGE));
        }

        if (dataTipInstance)
        {
            removeDynamicPartInstance("dataTip", dataTipInstance);
            systemManager.toolTipChildren.removeChild(DisplayObject(dataTipInstance));
            dataTipInstance = null;
        }
        
        super.system_mouseUpHandler(event);
    }

    //---------------------------------
    // Keyboard handlers
    //---------------------------------

    /**
     *  @private
     *  Handle keyboard events. Left/Down decreases the value
     *  decreases the value by stepSize. The opposite for
     *  Right/Up arrows. The Home and End keys set the value
     *  to the min and max respectively.
     */
    override protected function keyDownHandler(event:KeyboardEvent):void
    {
        super.keyDownHandler(event);
       
        if (event.isDefaultPrevented())
            return;
        
        // FIXME (hmuller): Provide a way to easily override the keyboard
        // behavior. This means having a callback in the subclasses
        // that tell the superclass all the positions in an array
        // but defaulting to the normal stepping behavior when no
        // array is returned. Consider reversed HSliders or VSliders.
        var prevValue:Number = this.value;
        var newValue:Number;
        var stopPropagation:Boolean = false;
        
        switch (event.keyCode)
        {
            case Keyboard.DOWN:
            case Keyboard.LEFT:
            {
                newValue = nearestValidValue(value - stepSize, snapInterval);
                setValue(newValue);
                stopPropagation = true;
                break;
            }

            case Keyboard.UP:
            case Keyboard.RIGHT:
            {
                newValue = nearestValidValue(value + stepSize, snapInterval);
                setValue(newValue);
                stopPropagation = true;
                break;
            }
            
            case Keyboard.HOME:
            {
                value = minimum;
                stopPropagation = true;
                break;
            }

            case Keyboard.END:
            {
                value = maximum;
                stopPropagation = true;
                break;
            }
        }

        if (value != prevValue)
            dispatchEvent(new Event(Event.CHANGE));
          
        // Gumbo redispatches scrolling keyboard events with cancelable=true
        // so typically we will preventDefault (read "cancel") here, rather
        // than stopping dispatching.
        if (stopPropagation)
        {
            if (event.cancelable)
                event.preventDefault();
            else
        	    event.stopPropagation();
        }
    }

    //---------------------------------
    // Track down handlers
    //---------------------------------
    
    /**
     *  @private
     *  Handle mouse-down events for the slider track. We
     *  calculate the value based on the new position and then
     *  move the thumb to the correct location as well as
     *  commit the value.
     */
    override protected function track_mouseDownHandler(event:MouseEvent):void
    {
        if (!enabled)
            return;
         
        // Offset the track-relative coordinates of this event so that
        // the thumb will end up centered over the mouse down location.
        var thumbW:Number = (thumb) ? thumb.width : 0;
        var thumbH:Number = (thumb) ? thumb.height : 0;
        var offsetX:Number = event.stageX - (thumbW / 2);
        var offsetY:Number = event.stageY - (thumbH / 2);
        var p:Point = track.globalToLocal(new Point(offsetX, offsetY));

        var newValue:Number = pointToValue(p.x, p.y);
        newValue = nearestValidValue(newValue, snapInterval);

        if (newValue != value)
        {
            var slideDuration:Number = getStyle("slideDuration");
            if (slideDuration != 0)
            {
                if (!animator)
                {
                    animator = new Animation();
                    var animTarget:AnimationTarget = new AnimationTarget(animationUpdateHandler);
                    animTarget.endFunction = animationEndHandler;
                    animator.animationTarget = animTarget;                    
                    // FIXME (chaase): hard-coding easer for now - how to style it?
                    animator.easer = new Sine(0);
                }
                animator.stop();
                animator.duration = slideDuration * 
                    (Math.abs(value - newValue) / (maximum - minimum));
                animator.motionPaths = new <MotionPath>[
                    new SimpleMotionPath("value", value, newValue)];
                
                dispatchEvent(new FlexEvent(FlexEvent.CHANGING));
                animator.play();
            }
            else
            {
                setValue(newValue);
                dispatchEvent(new Event(Event.CHANGE));
            }
        }

        event.updateAfterEvent();
    }
    
    /**
     * @private
     * Handles events from the Animation that runs the animated slide.
     * We just call setValue() with the current animated value
     */
    private function animationUpdateHandler(animation:Animation):void
    {
        setValue(animation.currentValue["value"]);
    }
    
    /**
     * @private
     * Handles end event from the Animation that runs the animated slide.
     * We dispatch the "change" event at this time, after the animation
     * is done.
     */
    private function animationEndHandler(animation:Animation):void
    {
        dispatchEvent(new Event("change"));
    }
}
}
