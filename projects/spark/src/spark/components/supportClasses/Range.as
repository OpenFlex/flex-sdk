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

package mx.components.baseClasses
{
    
import flash.events.Event;

import mx.components.baseClasses.FxComponent;

import mx.events.FlexEvent;

/**
 *  The FxRange class holds a value and an allowed range for that 
 *  value, defined by a <code>minimum</code> and <code>maximum</code> properties. 
 *  The <code>value</code> property 
 *  is always constrained to be between the current <code>minimum</code> and
 *  <code>maximum</code>, and the <code>minimum</code>,
 *  and <code>maximum</code> are always constrained
 *  to be in the proper numerical order such that
 *  (minimum &lt;= value &lt;= maximum) is <code>true</code>. 
 *  If <code>valueInterval</code> is not 0, 
 *  then <code>value</code> is also constrained to be a multiple of 
 *  <code>valueInterval</code>.
 * 
 *  <p>FxRange is a base class for various controls that require range
 *  functionality, including FxTrackBase and FxSpinner.</p>
 * 
 *  @see mx.components.baseClasses.FxTrackBase
 *  @see mx.components.FxSpinner
 */  
public class FxRange extends FxComponent
{
    include "../../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     */
    public function FxRange():void
    {
        super();
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //---------------------------------
    // maximum
    //---------------------------------   
    
    private var _maximum:Number = 100;
    
    private var maxChanged:Boolean = false;
    
    /**
     *  Number which represents the maximum value possible for 
     *  <code>value</code>. If the values for either 
     *  <code>minimum</code> or <code>value</code> are greater
     *  than <code>maximum</code>, they will be changed to 
     *  reflect the new <code>maximum</code>
     *
     *  @default 100
     */
    public function get maximum():Number
    {
        return _maximum;
    }

    public function set maximum(value:Number):void
    {
        if (value == _maximum)
            return;

        _maximum = value;
        maxChanged = true;

        invalidateProperties();
    }
    
    //---------------------------------
    // minimum
    //---------------------------------
    
    private var _minimum:Number = 0;
    
    private var minChanged:Boolean = false;
    
    /**
     *  Number which represents the minimum value possible for 
     *  <code>value</code>. If the values for either 
     *  <code>maximum</code> or <code>value</code> are less
     *  than <code>minimum</code>, they will be changed to 
     *  reflect the new <code>minimum</code>
     *
     *  @default 0
     */
    public function get minimum():Number
    {
        return _minimum;
    }
    
    public function set minimum(value:Number):void
    {
        if (value == _minimum)
            return;
        
        _minimum = value;
        minChanged = true;
        
        invalidateProperties();
    }

    //---------------------------------
    // stepSize
    //---------------------------------    
    
    private var _stepSize:Number = 1;
    
    private var stepSizeChanged:Boolean = false;

    /**
     *  <code>stepSize</code> is the amount that the value 
     *  changes when <code>step()</code> is called. It must
     *  be a multiple of <code>valueInterval</code> unless 
     *  <code>valueInterval</code> is 0. If <code>stepSize</code>
     *  is not a multiple, it is rounded to the nearest multiple 
     *  &gt;= <code>valueInterval</code>.
     *
     *  @default 1
     */
    public function get stepSize():Number
    {
        return _stepSize;
    }

    public function set stepSize(value:Number):void
    {
        if (value == _stepSize)
            return;
            
        _stepSize = value;
        stepSizeChanged = true;
        
        invalidateProperties();       
    }

    //---------------------------------
    // value
    //---------------------------------   
     
    private var _value:Number = 0;
    private var _changedValue:Number = 0;
    private var valueChanged:Boolean = false;
    
    [Bindable(event="valueCommit")]

    /**
     *  Number which represents the current value for this range. 
     *  <code>value</code> will always be constrained to lie 
     *  within the current <code>minimum</code> and 
     *  <code>maximum</code> values. It also must be a multiple
     *  of <code>valueInterval</code>.
     * 
     *  @default 0
     *  @see #setValue
     */
    public function get value():Number
    {
        return (valueChanged) ? _changedValue : _value;
    }


    /**
     *  Implementation note: we temporarily store the new value in
     *  _changedValue and then update _value, by calling setValue()
     *  in commitProperties().  Only one "valueCommit" event is
     *  dispatched, even if this property has effectively changed
     *  twice per nearestValidValue().
     *   
     *  @private
     */    
    public function set value(newValue:Number):void
    {
        if (newValue == _value)
            return;
        _changedValue = newValue;
        valueChanged = true;
        invalidateProperties();
    }
    
    //---------------------------------
    // valueInterval
    //---------------------------------   
     
    private var _valueInterval:Number = 1;

    private var valueIntervalChanged:Boolean = false;

    /**
     *  If greater than 0, <code>valueInterval</code> constrains
     *  <code>value</code> to multiples of <code>valueInterval</code>. 
     *  If it is 0, then 
     *  <code>value</code> can be any number between <code>minimum</code> and 
     *  <code>maximum</code>. 
     *  You can alsways set <code>value</code> to 
     *  <code>minimum</code> or <code>maximum</code>.
     *  Changing <code>valueInterval</code> also may change 
     *  <code>stepSize</code> to be a multiple of 
     *  <code>valueInterval</code> and &gt;= <code>valueInterval</code>.
     * 
     *  @default 1
     */
    public function get valueInterval():Number
    {
        return _valueInterval;
    }

    public function set valueInterval(value:Number):void
    {
        if (value == _valueInterval)
            return;
        
        _valueInterval = value;
        valueIntervalChanged = true;
        
        stepSizeChanged = true;
        
        invalidateProperties();
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    override protected function commitProperties():void
    {
        super.commitProperties();

        if (minimum > maximum)
        {
            // Check min <= max
            if (!maxChanged)
                _minimum = _maximum;
            else
                _maximum = _minimum;
        }

        if (valueChanged || maxChanged || minChanged || valueIntervalChanged)
        {
            setValue(nearestValidValue(_changedValue, valueInterval));
            valueChanged = false;
            maxChanged = false;
            minChanged = false;
            valueIntervalChanged = false;
        }
        
        if (stepSizeChanged)
        {
            if (valueInterval != 0)
                _stepSize = nearestValidInterval(_stepSize, valueInterval);
            
            stepSizeChanged = false;
        }
    }

    /**
     *  Round a value 
     *  to the closets multiple of the specified interval.
     *
     *  @param value The value to round.
     *
     *  @param interval The interval.
     *
     *  @return The multiple of <code>interval</code> closesst to <code>value</code>. 
     *  The minimum returned Number is <code>interval</code>.
     */
    protected function nearestValidInterval(value:Number, interval:Number):Number
    {
        var closest:Number = Math.round(value / interval)
                             * interval;
        
        if (Math.abs(closest) < interval)
            return interval;
        else
            return closest;
    }

    /**
     *  Rounds a value to the closest multiple of  
     *  the specified interval, and constrains the result to the range 
     *  defined by the FxRange object. 
     * 
     *  @param value The value to round.
     * 
     *  @param interval The interval to round the value against.
     *  If <code>interval</code> is 0, then the returned Number  
     *  is only bound to the range.
     * 
     *  @return The rounded value, or 0 if <code>value</code> is NaN.
     */
    protected function nearestValidValue(value:Number, interval:Number):Number
    {
        var closest:Number = value;
        
        if (isNaN(closest))
            closest = 0;

        // Round value to closest multiple of valueInterval
        if (interval != 0)
            closest = Math.round(closest / interval) * interval;    
        
        if (closest >= maximum)
            return maximum;
        else if (closest <= minimum)
            return minimum;

        if (interval == 0)
            return closest;

        // Round to the closest value (closest multiple, min, or max).
        var cdiff:Number = Math.abs(closest - value);
        var mindiff:Number = Math.abs(minimum - value);
        var maxdiff:Number = Math.abs(maximum - value);
        var min:Number = Math.min(cdiff, mindiff, maxdiff);

        // Return order maintains rounding up when in the middle.
        if (min == maxdiff)
            return maximum;
        else if (min == cdiff)
            return closest;
        else 
            return minimum;
    }
    
    /**
     *  Directly sets the <code>value</code> property and dispatches a "valueCommit"
     *  event if the property changes.  
     * 
     *  All updates to the value property cause a call to this method.
     * 
     *  Subclasses that ensure compliance with minimum, maximum, and
     *  valueInterval themselves can call this method to update
     *  the value property.
     * 
     *  @param value The new value of the <code>value</code> property.
     *  @see #nearestValidValue
     *  @param value The new value of <code>value</code>.
     */
    protected function setValue(value:Number):void
    {
        if (_value == value)
            return;
        
        _value = value;
        dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
    }
    
    /**
     *  Increase or decrease <code>value</code> by <code>stepSize</code>.
     *  The new value of <code>value</code> is a multiple of <code>stepSize</code>.
     *
     *  @param increase Whether the stepping action increases (<code>true</code>) or
     *  decreases (<code>false</code>) the <code>value</code>.
     */
    public function step(increase:Boolean = true):void
    {
        if (increase)
            setValue(nearestValidValue(value + stepSize, stepSize));
        else
            setValue(nearestValidValue(value - stepSize, stepSize));
    }
}

}