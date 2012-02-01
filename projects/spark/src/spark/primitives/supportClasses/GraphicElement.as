////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2003-2006 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.graphics.graphicsClasses
{
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.LineScaleMode;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Transform;

import mx.geom.Transform;
import mx.graphics.IGraphicElement;
import mx.graphics.IGraphicElementHost;
import mx.graphics.MaskType;
import mx.utils.MatrixUtil;
import mx.layout.ILayoutItem;
import mx.core.AdvancedLayoutFeatures;
import mx.core.IConstraintClient;
import mx.core.IInvalidating;
import mx.geom.CompoundTransform;
import mx.core.UIComponentGlobals;
import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;
import mx.filters.BaseFilter;
import mx.filters.IBitmapFilter;
import mx.graphics.IStroke;
import mx.managers.ILayoutManagerClient;
import mx.core.IVisualItem;
import flash.utils.Dictionary;


use namespace mx_internal;

/**
 *  A base class for defining individual graphic elements. Types of graphic elements include:
 *  <ul>
 *   <li>Shapes</li>
 *   <li>Text</li>
 *   <li>Raster images</li>
 *  </ul>
 *  
 *  <p>When defining a graphic element, you specify an explicit size for the element; 
 *  that is, you cannot use percentage sizing as you can when specifying the size of a control.</p>
 *  
 *  <p>The TBounds are the boundaries of an
 *  object in the object's parent coordinate space. The UBounds are the boundaries
 *  of an object in its own coordinate space.</p>
 */
public class GraphicElement extends EventDispatcher
    implements IGraphicElement, ILayoutItem, IConstraintClient,
    IInvalidating, IVisualItem
{
    include "../../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------

    /**
     *  The default value for the <code>maxWidth</code> property.
     *
     *  @default 10000
     */
    public static const DEFAULT_MAX_WIDTH:Number = 10000;

    /**
     *  The default value for the <code>maxHeight</code> property.
     *
     *  @default 10000
     */
    public static const DEFAULT_MAX_HEIGHT:Number = 10000;

     /**
     *  The default value for the <code>minWidth</code> property.
     *
     *  @default 0
     */
    public static const DEFAULT_MIN_WIDTH:Number = 0;

    /**
     *  The default value for the <code>minHeight</code> property.
     *
     *  @default 0
     */
    public static const DEFAULT_MIN_HEIGHT:Number = 0;

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    public function GraphicElement()
    {
        super();
        layoutFeatures = new AdvancedLayoutFeatures();
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    private var displayObjectChanged:Boolean;
    
    /**
     *  @private
     */
    private var _colorTransform:ColorTransform;
    
    /**
     *  @private
     */
    private var isMaskInElementSpace:Boolean;
    
    /**
     *  @private
     */
    private var _layer:Number = 0;

    /**
     *  @private
     *  Whether this element needs to have its
     *  commitProperties() method called.
     */
    mx_internal var invalidatePropertiesFlag:Boolean = false;

    /**
     *  @private
     *  Whether this element needs to have its
     *  measure() method called.
     */
    mx_internal var invalidateSizeFlag:Boolean = false;

    /**
     *  @private
     *  Whether this element needs to be have its
     *  updateDisplayList() method called.
     */
    mx_internal var invalidateDisplayListFlag:Boolean = false;


    /**
     *  Documentation is not currently available.
     */
    protected var layoutFeatures:AdvancedLayoutFeatures;
    //--------------------------------------------------------------------------
    //
    //  Properties: IGraphicElement
    //
    //--------------------------------------------------------------------------
    
    [Bindable("propertyChange")]
    /**
     * Documentation is not currently available
     */
    public function set offsets(value:CompoundTransform):void
    {
        var oldValue:CompoundTransform = layoutFeatures.offsets;
        
        if(layoutFeatures.offsets != null)
            layoutFeatures.offsets.removeEventListener(Event.CHANGE,transformOffsetsChangedHandler);
        layoutFeatures.offsets = value;
        if(layoutFeatures.offsets != null)
            layoutFeatures.offsets.addEventListener(Event.CHANGE,transformOffsetsChangedHandler);
        dispatchPropertyChangeEvent("offsets", oldValue, value);
    }
    
    /**
     * @private
     */
    public function get offsets():CompoundTransform
    {
        return layoutFeatures.offsets;
    }

    
    
    protected function invalidateTransform(changeInvalidatesLayering:Boolean = true,triggerLayout:Boolean = true):void
    {
        if(changeInvalidatesLayering)
            notifyElementLayerChanged();
        if(triggerLayout)
        {
            invalidateParentSizeAndDisplayList();
            invalidateProperties();
        }
        layoutFeatures.updatePending = true;
    }

    /**
     * @private
     */
    private function transformOffsetsChangedHandler(e:Event):void
    {
        invalidateTransform();
    }
    
    //----------------------------------
    //  alpha
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the alpha property.
     */
    private var _alpha:Number = 1.0;
    
    /**
     *  @private
     */
    private var alphaChanged:Boolean = false;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  @inheritDoc
     */
    public function get alpha():Number
    {
        return _alpha;
    }

    /**
     *  @private
     */
    public function set alpha(value:Number):void
    {
        if (_alpha == value)
            return;

        var oldValue:Number = _alpha;
        _alpha = value;
        dispatchPropertyChangeEvent("alpha", oldValue, value);

        alphaChanged = true;
        notifyElementLayerChanged();
        invalidateProperties();
    }

    //----------------------------------
    //  baseline
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the baseline property.
     */
    private var _baseline:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Documentation is not currently available.
     */
    public function get baseline():Number
    {
        return _baseline;
    }

    /**
     *  @private
     */
    public function set baseline(value:Number):void
    {
        if (_baseline == value)
            return;

        var oldValue:Number = _baseline;
        _baseline = value;
        dispatchPropertyChangeEvent("baseline", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  blendMode
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the blendMode property.
     */
    private var _blendMode:String = BlendMode.NORMAL;
    
    /**
     *  @private
     */
    private var blendModeChanged:Boolean;
    private var blendModeExplicitlySet:Boolean = false;

    [Bindable("propertyChange")]
    [Inspectable(category="General", enumeration="add,alpha,darken,difference,erase,hardlight,invert,layer,lighten,multiply,normal,subtract,screen,overlay", defaultValue="normal")]

    /**
     *  @inheritDoc
     */
    public function get blendMode():String
    {
        if (blendModeExplicitlySet)
            return _blendMode;
        else return BlendMode.LAYER;
    }

    /**
     *  @private
     */
    public function set blendMode(value:String):void
    {
        if (blendModeExplicitlySet && _blendMode == value)
            return;

        var oldValue:String = _blendMode;
        _blendMode = value;
        dispatchPropertyChangeEvent("blendMode", oldValue, value);

        blendModeExplicitlySet = true;

        blendModeChanged = true;
        notifyElementLayerChanged();
        invalidateProperties();
    }

    //----------------------------------
    //  bottom
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the blendMode property.
     */
    private var _bottom:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Documentation is not currently available.
     */
    public function get bottom():Number
    {
        return _bottom;
    }

    /**
     *  @private
     */
    public function set bottom(value:Number):void
    {
        if (_bottom == value)
            return;

        var oldValue:Number = _bottom;
        _bottom = value;
        dispatchPropertyChangeEvent("bottom", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  elementHost
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the elementHost property.
     */
    protected var _host:IGraphicElementHost;

    /**
     *  The Group or Graphic tag that contains this element.
     */
    public function get elementHost():IGraphicElementHost
    {
        return _host;
    }

    /**
     *  @private
     */
    public function set elementHost(value:IGraphicElementHost):void
    {
        if (_host !== value)
        {
            _host = value;
            /* if (_mask)
                _host.addMaskElement(_mask); */
            if (_host && _host is IInvalidating)
            {
                IInvalidating(_host).invalidateProperties();
                IInvalidating(_host).invalidateSize();
                IInvalidating(_host).invalidateDisplayList();
            }
        }
    }

    //----------------------------------
    //  explicitHeight
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the explicitHeight property.
     */
    private var _explicitHeight:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  @copy mx.core.UIComponent#explicitHeight
     */
    public function get explicitHeight():Number
    {
        return _explicitHeight;
    }

    /**
     *  @private
     */
    public function set explicitHeight(value:Number):void
    {
        if (_explicitHeight == value)
            return;

        // height can be pixel or percent, not both
        if (!isNaN(value))
            percentHeight = NaN;

        var oldValue:Number = _explicitHeight;
        _explicitHeight = value;
        dispatchPropertyChangeEvent("explicitHeight", oldValue, value);

        invalidateSize();
        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  explicitWidth
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the explicitHeight property.
     */
    private var _explicitWidth:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  @copy mx.core.UIComponent#explicitHeight
     */
    public function get explicitWidth():Number
    {
        return _explicitWidth;
    }

    /**
     *  @private
     */
    public function set explicitWidth(value:Number):void
    {
        if (_explicitWidth == value)
            return;

        // height can be pixel or percent, not both
        if (!isNaN(value))
            percentWidth = NaN;

        var oldValue:Number = _explicitWidth;
        _explicitWidth = value;
        dispatchPropertyChangeEvent("explicitWidth", oldValue, value);

        invalidateSize();
        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  filters
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the filters property.
     */
    private var _filters:Array = [];
    
    /**
     *  @private
     */
    private var filtersChanged:Boolean;

    /**
     *  @private
     */
    private var _clonedFilters:Array;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  An indexed array that contains each filter object currently associated with the graphic element. 
     *  The mx.filters.* package contains several classes that define specific filters you can use.
     */
    public function get filters():Array
    {
        return _filters;
    }

    /**
     *  @private
     */
    public function set filters(value:Array):void
    {
        var i:int = 0;
        var oldFilters:Array = _filters ? _filters.slice() : null;
        var len:int = oldFilters ? oldFilters.length : 0;
        var edFilter:IEventDispatcher;

        for (i = 0; i < len; i++)
        {
            edFilter = value[i] as IEventDispatcher;
            if (edFilter)
                edFilter.removeEventListener(BaseFilter.CHANGE, filterChangedHandler);
        }

        _clonedFilters = [];
        _filters = value;
        len = value.length;

        for (i = 0; i < len; i++)
        {
            if (value[i] is IBitmapFilter)
            {
                edFilter = value[i] as IEventDispatcher;
                if (edFilter)
                    edFilter.addEventListener(BaseFilter.CHANGE, filterChangedHandler);
                _clonedFilters.push(IBitmapFilter(value[i]).clone());
            }
            else
            {
                _clonedFilters.push(value[i]);
            }
        }

        dispatchPropertyChangeEvent("filters", oldFilters, _filters);

        filtersChanged = true;
        notifyElementLayerChanged();
        invalidateProperties();
    }

    //----------------------------------
    //  height
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the height property.
     */
    mx_internal var _height:Number = 0;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    [PercentProxy("percentHeight")]

    /**
     *  The height of the graphic element.
     *
     *  @default 0
     */
    public function get height():Number
    {
        return _height;
    }

    /**
     *  @private
     */
    
    public function set height(value:Number):void
    {
        explicitHeight = value;

        if (_height == value)
            return;

        var oldValue:Number = _height;
        _height = value;
        dispatchPropertyChangeEvent("height", oldValue, value);

        // Invalidate the display list, since we're changing the actual width
        // and we're not going to correctly detect whether the layout sets
        // new actual width different from our previous value.
        // TODO EGeorgie: is this worth optimizing?
        invalidateDisplayList();
    }

    //----------------------------------
    //  horizontalCenter
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the horizontalCenter property.
     */
    private var _horizontalCenter:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Documentation is not currently available.
     */
    public function get horizontalCenter():Number
    {
        return _horizontalCenter;
    }

    /**
     *  @private
     */
    public function set horizontalCenter(value:Number):void
    {
        if (_horizontalCenter == value)
            return;

        var oldValue:Number = _horizontalCenter;
        _horizontalCenter = value;
        dispatchPropertyChangeEvent("horizontalCenter", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  left
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the left property.
     */
    private var _left:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Documentation is not currently available.
     */
    public function get left():Number
    {
        return _left;
    }

    /**
     *  @private
     */
    public function set left(value:Number):void
    {
        if (_left == value)
            return;

        var oldValue:Number = _left;
        _left = value;
        dispatchPropertyChangeEvent("left", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  mask
    //----------------------------------

    /**
     *  @private
     *  Storage for the mask property.
     */
    private var _mask:DisplayObject;
    
    /**
     *  @private
     */
    private var maskChanged:Boolean;

    /**
     *  @private
     */
    private var previousMask:DisplayObject;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  @inheritDoc
     */
    public function get mask():DisplayObject
    {
        return _mask;
    }

    /**
     *  @private
     */
    public function set mask(value:DisplayObject):void
    {
        if (_mask == value)
            return;

        var oldValue:DisplayObject = _mask;
        previousMask = _mask;
        _mask = value;
        dispatchPropertyChangeEvent("mask", oldValue, value);
        maskChanged = true;
        maskTypeChanged = true;
        isMaskInElementSpace = false;
        notifyElementLayerChanged();
        invalidateProperties();
    }

    //----------------------------------
    //  maskType
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the maskType property.
     */
    private var _maskType:String = MaskType.CLIP;
    
    /**
     *  @private
     */
    private var maskTypeChanged:Boolean;

    [Bindable("propertyChange")]
    [Inspectable(category="General", enumeration="clip,alpha", defaultValue="clip")]
    
    /**
     *  @inheritDoc
     */
    public function get maskType():String
    {
        return _maskType;
    }

    /**
     *  @private
     */
    public function set maskType(value:String):void
    {
        if (_maskType == value)
            return;

        var oldValue:String = _maskType;
        _maskType = value;
        dispatchPropertyChangeEvent("maskType", oldValue, value);

        maskTypeChanged = true;
        invalidateProperties();
    }

    //----------------------------------
    //  maxHeight
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the maxHeight property.
     */
    private var _maxHeight:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  @copy mx.core.UIComponent#maxHeight
     */
    public function get maxHeight():Number
    {
        // TODO!!! Examine this logic, Make this arbitrarily large (use UIComponent max)
        return !isNaN(_maxHeight) ? _maxHeight : DEFAULT_MAX_HEIGHT;
    }

    /**
     *  @private
     */
    public function set maxHeight(value:Number):void
    {
        if (_maxHeight == value)
            return;

        var oldValue:Number = _maxHeight;
        _maxHeight = value;
        dispatchPropertyChangeEvent("maxHeight", oldValue, value);

        invalidateSize();
        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  maxWidth
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the maxHeight property.
     */
    private var _maxWidth:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  @copy mx.core.UIComponent#maxWidth
     */
    public function get maxWidth():Number
    {
        // TODO!!! Examine this logic, Make this arbitrarily large (use UIComponent max)
        return !isNaN(_maxWidth) ? _maxWidth : DEFAULT_MAX_WIDTH;
    }

    /**
     *  @private
     */
    public function set maxWidth(value:Number):void
    {
        if (_maxWidth == value)
            return;

        var oldValue:Number = _maxWidth;
        _maxWidth = value;
        dispatchPropertyChangeEvent("maxWidth", oldValue, value);

        invalidateSize();
        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  measuredHeight
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the measuredHeight property.
     */
    private var _measuredHeight:Number = 0;
    
    /**
     *  @copy mx.core.UIComponent#measuredHeight
     */
    public function get measuredHeight():Number
    {
        return _measuredHeight;
    }
    
    /**
     *  @private
     */
    public function set measuredHeight(value:Number):void
    {
        _measuredHeight = value;
    }

    //----------------------------------
    //  measuredWidth
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the measuredWidth property.
     */
    private var _measuredWidth:Number = 0;
    
    /**
     *  @copy mx.core.UIComponent#measuredWidth
     */
    public function get measuredWidth():Number
    {
        return _measuredWidth;
    }
    
    /**
     *  @private
     */
    public function set measuredWidth(value:Number):void
    {
        _measuredWidth = value;
    }

    //----------------------------------
    //  measuredX
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the measuredX property.
     */
    private var _measuredX:Number = 0;
    
    /**
     *  The default measured bounds top-left corner relative to the origin of the element.     
     */
    public function get measuredX():Number
    {
        return _measuredX;
    }
    
    /**
     *  @private
     */
    public function set measuredX(value:Number):void
    {
        _measuredX = value;
    }

    //----------------------------------
    //  measuredY
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the measuredY property.
     */
    private var _measuredY:Number = 0;
    
    /**
     *  The default measured bounds top-left corner relative to the origin of the element.     
     */
    public function get measuredY():Number
    {
        return _measuredY;
    }
    
    /**
     *  @private
     */
    public function set measuredY(value:Number):void
    {
        _measuredY = value;
    }

    //----------------------------------
    //  minHeight
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the minHeight property.
     */
    private var _minHeight:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  @copy mx.core.UIComponent#minHeight
     */
    public function get minHeight():Number
    {
        // TODO!!! Examine this logic
        return !isNaN(_minHeight) ? _minHeight : DEFAULT_MIN_HEIGHT;
    }

    /**
     *  @private
     */
    public function set minHeight(value:Number):void
    {
        if (_minHeight == value)
            return;

        var oldValue:Number = _minHeight;
        _minHeight = value;
        dispatchPropertyChangeEvent("minHeight", oldValue, value);

        invalidateSize();
        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  minWidth
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the minWidth property.
     */
    private var _minWidth:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  @copy mx.core.UIComponent#minWidth
     */
    public function get minWidth():Number
    {
        // TODO!!! Examine this logic
        return !isNaN(_minWidth) ? _minWidth : DEFAULT_MIN_WIDTH;
    }

    /**
     *  @private
     */
    public function set minWidth(value:Number):void
    {
        if (_minWidth == value)
            return;

        var oldValue:Number = _minWidth;
        _minWidth = value;
        dispatchPropertyChangeEvent("minWidth", oldValue, value);

        invalidateSize();
        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  percentHeight
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the percentHeight property.
     */
    private var _percentHeight:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  @copy mx.core.UIComponent#percentHeight
     */
    public function get percentHeight():Number
    {
        return _percentHeight;
    }

    /**
     *  @private
     */
    public function set percentHeight(value:Number):void
    {
        if (_percentHeight == value)
            return;

        if (!isNaN(value))
            explicitHeight = NaN;

        var oldValue:Number = _percentHeight;
        _percentHeight = value;
        dispatchPropertyChangeEvent("percentHeight", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  percentWidth
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the percentWidth property.
     */
    private var _percentWidth:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  @copy mx.core.UIComponent#percentWidth
     */
    public function get percentWidth():Number
    {
        return _percentWidth;
    }

    /**
     *  @private
     */
    public function set percentWidth(value:Number):void
    {
        if (_percentWidth == value)
            return;

        if (!isNaN(value))
            explicitWidth = NaN;

        var oldValue:Number = _percentWidth;
        _percentWidth = value;
        dispatchPropertyChangeEvent("percentWidth", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  right
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the right property.
     */
    private var _right:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Documentation is not currently available.
     */
    public function get right():Number
    {
        return _right;
    }

    /**
     *  @private
     */
    public function set right(value:Number):void
    {
        if (_right == value)
            return;

        var oldValue:Number = _right;
        _right = value;
        dispatchPropertyChangeEvent("right", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  rotation
    //----------------------------------


    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Indicates the rotation of the element, in degrees,
     *  from the transform point.
     */
    public function get rotationX():Number
    {
        return layoutFeatures.layoutRotationX;
    }

    /**
     *  @private
     */
    public function set rotationX(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutRotationX;
        if (oldValue == value)
            return;

        layoutFeatures.layoutRotationX = value;
        dispatchPropertyChangeEvent("rotationX", oldValue, value);
        invalidateTransform();
    }

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Indicates the rotation of the element, in degrees,
     *  from the transform point.
     */
    public function get rotationY():Number
    {
        return layoutFeatures.layoutRotationY;
    }

    /**
     *  @private
     */
    public function set rotationY(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutRotationY;
        if (oldValue == value)
            return;

        layoutFeatures.layoutRotationY = value;
        dispatchPropertyChangeEvent("rotationY", oldValue, value);
        invalidateTransform();
    }
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Indicates the rotation of the element, in degrees,
     *  from the transform point.
     */
    public function get rotationZ():Number
    {
        return layoutFeatures.layoutRotationZ;
    }

    /**
     *  @private
     */
    public function set rotationZ(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutRotationZ;
        if (oldValue == value)
            return;

        layoutFeatures.layoutRotationZ = value;
        dispatchPropertyChangeEvent("rotationZ", oldValue, value);
        dispatchPropertyChangeEvent("rotation", oldValue, value);
        invalidateTransform();
    }

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Indicates the rotation of the element, in degrees,
     *  from the transform point.
     */
    public function get rotation():Number
    {
        return layoutFeatures.layoutRotationZ;
    }

    /**
     *  @private
     */
    public function set rotation(value:Number):void
    {
        rotationZ = value;
    }

    //----------------------------------
    //  scaleX
    //----------------------------------

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  The horizontal scale (percentage) of the element
     *  as applied from the transform point.
     */
    public function get scaleX():Number
    {
        return layoutFeatures.layoutScaleX;
    }

    /**
     *  @private
     */
    public function set scaleX(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutScaleX;
        if (oldValue == value)
            return;

        layoutFeatures.layoutScaleX = value;
        dispatchPropertyChangeEvent("scaleX", oldValue, value);
        invalidateTransform();
    }

    //----------------------------------
    //  scaleY
    //----------------------------------

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  The vertical scale (percentage) of the element
     *  as applied from the transform point.
     */
    public function get scaleY():Number
    {
        return layoutFeatures.layoutScaleY;
    }

    /**
     *  @private
     */
    public function set scaleY(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutScaleY;
        if (oldValue == value)
            return;

        layoutFeatures.layoutScaleY = value;
        dispatchPropertyChangeEvent("scaleY", oldValue, value);
        invalidateTransform();
    }

    //----------------------------------
    //  scaleZ
    //----------------------------------

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  The z scale (percentage) of the element
     *  as applied from the transform point.
     */
    public function get scaleZ():Number
    {
        return layoutFeatures.layoutScaleZ;
    }

    /**
     *  @private
     */
    public function set scaleZ(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutScaleZ;
        if (oldValue == value)
            return;

        layoutFeatures.layoutScaleZ = value;
        dispatchPropertyChangeEvent("scaleZ", oldValue, value);
        invalidateTransform();
    }

    //----------------------------------
    //  top
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the top property.
     */
    private var _top:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Documentation is not currently available.
     */
    public function get top():Number
    {
        return _top;
    }

    /**
     *  @private
     */
    public function set top(value:Number):void
    {
        if (_top == value)
            return;

        var oldValue:Number = _top;
        _top = value;
        dispatchPropertyChangeEvent("top", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  transform
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the transform property.
     */
    private var _transform:flash.geom.Transform;

    /**
     *  @copy mx.core.UIComponent#transform
     */
    public function get transform():flash.geom.Transform
    {
        if (!_transform) 
            setTransform(new mx.geom.Transform());
            
        return _transform;
    }

    /**
     *  @private
     */
    public function set transform(value:flash.geom.Transform):void
    {
        setTransform(value);

        if (_transform)
        {
            if(_transform.matrix != null)
            {
                layoutFeatures.layoutMatrix = _transform.matrix.clone();
            }
            else if (_transform.matrix3D != null)
            {    
                layoutFeatures.layoutMatrix3D = _transform.matrix3D.clone();
            }          
        }
        
        _colorTransform = _transform ? _transform.colorTransform : null;
         
        invalidateTransform();
    }

    /**
     * @private
     */ 
    private function setTransform(value:flash.geom.Transform):void
    {
        // Clean up the old event listeners
        var oldTransform:mx.geom.Transform = _transform as mx.geom.Transform;
        if (oldTransform)
        {
            oldTransform.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, transformPropertyChangeHandler);
        }

        var newTransform:mx.geom.Transform = value as mx.geom.Transform;

        if (newTransform)
        {
            newTransform.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, transformPropertyChangeHandler);
        }

        _transform = value;
    }
    
    /**
     *  The transform matrix that is used to calculate the component's layout relative to its siblings. 
     *  This matrix is modified by the values of the <code>offset</code> property to determine its final, computed matrix.
     */
    public function get matrix():Matrix
    {
        return layoutFeatures.layoutMatrix;         
    }

    /**
     * @private
     */
    public function set matrix(value:Matrix):void
    {
        layoutFeatures.layoutMatrix = value;
        invalidateTransform();
    }

    /**
     *  The transform matrix that is used to calculate a component's layout relative to its siblings. 
     *  This matrix is modified by the values of the <code>offset</code> property to determine its final, computed matrix.
     */
    public function set matrix3D(value:Matrix3D):void
    {
        layoutFeatures.layoutMatrix3D = value;
        invalidateTransform();
    }

    /**
     * @private
     */
    public function get matrix3D():Matrix3D
    {
        return layoutFeatures.layoutMatrix3D;           
    }
    
    /**
     *  
     */
    public function transformAround(rx:Number,ry:Number,rz:Number,sx:Number,sy:Number,sz:Number,tx:Number,ty:Number,tz:Number):void
    {
        layoutFeatures.transformAround(rx,ry,rz,sx,sy,sz,tx,ty,tz,true);
        invalidateTransform();
    }       

    //----------------------------------
    //  transformX
    //----------------------------------
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  The x position transform point of the element.
     */
    public function get transformX():Number
    {
        return layoutFeatures.transformX;
    }

    /**
     *  @private
     */
    public function set transformX(value:Number):void
    {
        var oldValue:Number = layoutFeatures.transformX;
        if ( oldValue == value)
            return;
            
        layoutFeatures.transformX = value;
        dispatchPropertyChangeEvent("transformX", oldValue, value);
        invalidateTransform(false);
    }

    //----------------------------------
    //  transformY
    //----------------------------------
    

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  The y position transform point of the element.
     */
    public function get transformY():Number
    {
        return layoutFeatures.transformY;
    }

    /**
     *  @private
     */
    public function set transformY(value:Number):void
    {
        var oldValue:Number = layoutFeatures.transformY;
        if (oldValue == value)
            return;
        layoutFeatures.transformY = value;
        dispatchPropertyChangeEvent("transformY", oldValue, value);
        invalidateTransform(false);
    }

    //----------------------------------
    //  transformZ
    //----------------------------------
    

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  The y position transform point of the element.
     */
    public function get transformZ():Number
    {
        return layoutFeatures.transformZ;
    }

    /**
     *  @private
     */
    public function set transformZ(value:Number):void
    {
        var oldValue:Number = layoutFeatures.transformZ;
        if (oldValue == value)
            return;
        layoutFeatures.transformZ = value;
        dispatchPropertyChangeEvent("transformZ", oldValue, value);
        invalidateTransform();
    }

    //----------------------------------
    //  verticalCenter
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the verticalCenter property.
     */
    private var _verticalCenter:Number;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  Documentation is not currently available.
     */
    public function get verticalCenter():Number
    {
        return _verticalCenter;
    }

    /**
     *  @private
     */
    public function set verticalCenter(value:Number):void
    {
        if (_verticalCenter == value)
            return;

        var oldValue:Number = _verticalCenter;
        _verticalCenter = value;
        dispatchPropertyChangeEvent("verticalCenter", oldValue, value);

        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  width
    //----------------------------------

    /**
     *  @private
     *  Storage for the width property.
     */
    mx_internal var _width:Number = 0;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    [PercentProxy("percentWidth")]

    /**
     *  The width of the graphic element.
     *
     *  @default 0
     */
    public function get width():Number
    {
        return _width;
    }

    /**
     *  @private
     */
    public function set width(value:Number):void
    {
        explicitWidth = value;

        if (_width == value)
            return;

        var oldValue:Number = _width;
        _width = value;
        dispatchPropertyChangeEvent("width", oldValue, value);

        // Invalidate the display list, since we're changing the actual height
        // and we're not going to correctly detect whether the layout sets
        // new actual height different from our previous value.
        // TODO EGeorgie: is this worth optimizing?
        invalidateDisplayList();
    }

    //----------------------------------
    //  layer
    //----------------------------------  
    /**
     *  @inheritDoc
     */
    public function get layer():Number
    {
        return layoutFeatures.layer;
    }

    /**
     *  @private
     */
    public function set layer(value:Number):void
    {
        if(value == layer)
            return;
         layoutFeatures.layer = value;  
        if(_host != null && _host is UIComponent)
            (_host as UIComponent).invalidateLayering();
    }

    //----------------------------------
    //  x
    //----------------------------------  
    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  The x position of the graphic element.
     */
    public function get x():Number
    {
        return layoutFeatures.layoutX;
    }

    /**
     *  @private
     */
    public function set x(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutX;
        if (oldValue == value)
            return;

        layoutFeatures.layoutX = value;
        dispatchPropertyChangeEvent("x", oldValue, value);
        invalidateTransform(false);
    }

    //----------------------------------
    //  y
    //----------------------------------   

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  The y position of the graphic element.
     */
    public function get y():Number
    {
        return layoutFeatures.layoutY;
    }

    /**
     *  @private
     */
    public function set y(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutY;
        if (oldValue == value)
            return;

        layoutFeatures.layoutY = value;
        dispatchPropertyChangeEvent("y", oldValue, value);
        invalidateTransform(false);
    }

    //----------------------------------
    //  z
    //----------------------------------   

    [Bindable("propertyChange")]
    [Inspectable(category="General")]
    
    /**
     *  The y position of the graphic element.
     */
    public function get z():Number
    {
        return layoutFeatures.layoutZ;
    }

    /**
     *  @private
     */
    public function set z(value:Number):void
    {
        var oldValue:Number = layoutFeatures.layoutZ;
        if (oldValue == value)
            return;
        
        layoutFeatures.layoutZ = value;
        dispatchPropertyChangeEvent("z", oldValue, value);
        invalidateTransform();
    }

    //----------------------------------
    //  visible
    //----------------------------------

    /**
     *  @private
     *  Storage for the visible property.
     */
    private var _visible:Boolean = true;
    
    /**
     *  @private
     */
    private var visibleChanged:Boolean;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  @inheritDoc
     */
    public function get visible():Boolean
    {
        return _visible;
    }

    /**
     *  @private
     */
    public function set visible(value:Boolean):void
    {
        if (_visible == value)
            return;

        var oldValue:Boolean = _visible;
        _visible = value;
        dispatchPropertyChangeEvent("visible", oldValue, value);

        visibleChanged = true;

        invalidateProperties();
        
        // TODO: This is a quick fix for MXMLG-228. We should
        // investigate a better solution.
        notifyElementLayerChanged();
    }

    //--------------------------------------------------------------------------
    //
    //  Properties: IDisplayObjectElement
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  displayObject
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the displayObject property.
     */
    private var _displayObject:DisplayObject;

    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  Documentation is not currently available.
     */
    public function get displayObject():DisplayObject
    {
        return _displayObject;
    }

    /**
     *  @private
     */
    public function set displayObject(value:DisplayObject):void
    {
        if (_displayObject == value)
            return;

        var oldValue:DisplayObject = _displayObject;

        //esg: matrix3D's are owned by a DO, so we need to reclaim any
        // matrix3D we might have assigned.
        if(oldValue != null)
            oldValue.transform.matrix3D = null;
        
        _displayObject = value;
        dispatchPropertyChangeEvent("displayObject", oldValue, value);

        // We need to apply the display object related properties.
        displayObjectChanged = true;
        invalidateProperties();

        // New display object, we need to redraw
        invalidateDisplayList();
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  actualPosition
    //----------------------------------

    /**
     *  The item TBounds top left corner coordinates. 
     */
    public function get actualPosition():Point
    {
        var topLeft:Point = new Point(measuredX, measuredY);

        // Account for transform
        var m:Matrix = computeMatrix(true /*actualMatrix*/);
        if (m)
        {
            // Calculate the vector from pre-transform top-left to
            // post-transform top-left:
            computeTopLeft(topLeft, _width, _height, m);
        }
        else
        {
            topLeft.x += layoutFeatures.layoutX;
            topLeft.y += layoutFeatures.layoutY;
        }

        // Take stroke into account:
        // TODO EGeorgie: We assume that the stroke extents are even on both sides.
        // and that's not necessarily true.
        var strokeExtents:Point = getStrokeExtents();
        topLeft.x -= strokeExtents.x * 0.5;
        topLeft.y -= strokeExtents.y * 0.5;

        return topLeft;
    }

    //----------------------------------
    //  actualSize
    //----------------------------------

    /**
     *  The item TBounds size. 
     */
    public function get actualSize():Point
    {
        return transformSizeForLayout(_width, _height, true /*actualMatrix*/);
    }

    //----------------------------------
    //  drawX
    //----------------------------------

    /**
     *  The x position where the element should be drawn.
     */
    protected function get drawX():Number
    {
        // Draw position depends upon which coordinate space we are located in.
        // TODO!!! We need to apply all of the transforms of our ancestors
        if(displayObject != null)
            return 0;
        var result:Number = layoutFeatures.layoutX;
        if(layoutFeatures.offsets != null)
            result +=  layoutFeatures.offsets.x;    
        return sharedDisplayObject && sharedDisplayObject != elementHost ? result - sharedDisplayObject.x : result;
    }
    
    //----------------------------------
    //  drawY
    //----------------------------------

    /**
     *  The y position where the element should be drawn.
     */
    protected function get drawY():Number
    {
        // Draw position depends upon which coordinate space we are located in.
        // TODO!!! We need to apply all of the transforms of our ancestors
        if(displayObject != null)
            return 0;
        var result:Number = layoutFeatures.layoutY;
        if(layoutFeatures.offsets != null)
            result +=  layoutFeatures.offsets.y;    
        return sharedDisplayObject && sharedDisplayObject != elementHost ? result - sharedDisplayObject.y : result;
    }
    
    //----------------------------------
    //  includeInLayout
    //----------------------------------

    /**
     *  @private
     *  Storage for the includeInLayout property.
     */
    private var _includeInLayout:Boolean = true;

    [Bindable("propertyChange")]
    [Inspectable(category="General", defaultValue="true")]

    /**
     *  Specifies whether this element is included in the layout of the group.
     *
     *  @default true
     */
    public function get includeInLayout():Boolean
    {
        return _includeInLayout;
    }
    
    /**
     *  @private
     */
    public function set includeInLayout(value:Boolean):void
    {
        if (_includeInLayout == value)
            return;

        var oldValue:Boolean = _includeInLayout;
        _includeInLayout = value;
        dispatchPropertyChangeEvent("includeInLayout", oldValue, value);
            
        invalidateParentSizeAndDisplayList();
    }

    //----------------------------------
    //  maxSize
    //----------------------------------

    /**
     *  The TBounds of the maximum item size.
     *  <code>preferredSize</code> &lt;= <code>maxSize</code> must be true.
     */
    public function get maxSize():Point
    {
        return transformSizeForLayout(maxWidth, maxHeight,
                                      false /*actualMatrix*/);
    }

    //----------------------------------
    //  minSize
    //----------------------------------

    /**
     *  The TBounds of the minimum item size.
     *  <code>minSize</code> %lt;= <code>preferredSize</code> must be true.
     */
    public function get minSize():Point
    {
        return transformSizeForLayout(minWidth, minHeight, false /*actualMatrix*/);
    }

    //----------------------------------
    //  percentSize
    //----------------------------------

    /**
     *  The desired item TBounds size
     *  as a percentage of parent UBounds. Could be NaN.
     */
    public function get percentSize():Point
    {
        return new Point(percentWidth, percentHeight);
    }

    //----------------------------------
    //  preferredSize
    //----------------------------------

    /**
     *  The TBounds of the preferred item size.
     *  The preferred size is usually based on the default
     *  item size and any explicit size overrides.
     */
    public function get preferredSize():Point
    {
        return transformSizeForLayout(preferredWidthPreTransform(),
                                      preferredHeightPreTransform(),
                                      false /*actualMatrix*/);
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  Documentation is not currently available.
     */
    public function createDisplayObject():DisplayObject
    {
        if (displayObject)
            return displayObject;
        
        return new Sprite();
    }
    
    
    public function destroyDisplayObject():void
    {
        // TODO!! Figure out what cleanup to do
        if (displayObject)
        {
            if (displayObject.parent)
                displayObject.parent.removeChild(displayObject);
            displayObject = null;
        }
    }
       
    /**
     *  Documentation is not currently available.
     */
    public function get needsDisplayObject():Boolean
    {
        var result:Boolean;
        result = ((_filters && _filters.length > 0) || 
            _blendMode != BlendMode.NORMAL || _mask ||
            layoutFeatures.layoutScaleX != 1 || layoutFeatures.layoutScaleY != 1 || layoutFeatures.layoutScaleZ != 1 ||
            layoutFeatures.layoutRotationX != 0 || layoutFeatures.layoutRotationY != 0 || layoutFeatures.layoutRotationZ != 0 ||
            layoutFeatures.layoutZ  != 0 ||  
            _colorTransform != null ||
            _alpha != 1 ||
            _layer != 0);

        if(layoutFeatures.offsets != null)
        {
            var o:CompoundTransform = layoutFeatures.offsets;
            result = result || (o.scaleX != 1 || o.scaleY != 1 || o.scaleZ != 1 ||
            o.rotationX != 0 || o.rotationY != 0 || o.rotationZ != 0 || o.z  != 0);  
            
        }
        return result;
    }
    
    public function get nextSiblingNeedsDisplayObject():Boolean
    {
        // TODO: The displayObject && visible test is a quick fix for MXMLG-228.
        // Should investigate a better solution.
        return needsDisplayObject || (displayObject && visible == false);
    }
    
    private var _sharedDisplayObject:DisplayObject;
    
    public function set sharedDisplayObject(value:DisplayObject):void
    {
        _sharedDisplayObject = value;
    }
    
    public function get sharedDisplayObject():DisplayObject
    {
        return _sharedDisplayObject;
    }
    
    protected function get drawnDisplayObject():DisplayObject
    {
        return displayObject ? displayObject : sharedDisplayObject;
    }

    /**
     *  Returns a bitmap snapshot of the GraphicElement.
     *  The bitmap contains all transformations and is reduced
     *  to fit the visual bounds of the object.
     */
    public function getBitmapData(transparent:Boolean = true, fillColor:uint = 0xFFFFFFFF):BitmapData
    {
        // NOTE: This code will not work correctly when we share
        // display objects across multiple graphic elements.
        var bitmapData:BitmapData = new BitmapData(actualSize.x, actualSize.y, transparent, fillColor);

        var m:Matrix = displayObject.transform.matrix.clone();
        m.translate(-actualPosition.x, -actualPosition.y);
        
        if (displayObject && nextSiblingNeedsDisplayObject)
            bitmapData.draw(displayObject, m);
        else
        {
            var oldDisplayObject:DisplayObject = displayObject;
            displayObject = new Sprite();
            invalidateDisplayList();
            validateDisplayList();
            
            bitmapData.draw(displayObject);
            
            displayObject = oldDisplayObject;
                
        }
        return bitmapData;
    }

    /**
     *  Documentation is not currently available.
     */
    public function applyMask():void
    {
        if (displayObject && _mask)
        {
            displayObject.mask = _mask;
            if (!isMaskInElementSpace)
            {
                var maskMatrix:Matrix = _mask.transform.matrix;
                maskMatrix.concat(displayObject.transform.matrix);
                _mask.transform.matrix = maskMatrix;
                isMaskInElementSpace = true;
            }
        }
    }

    /**
     *  Documentation is not currently available.
     */
    protected function applyMaskType():void
    {
        if (_mask)
        {
            if (_maskType == MaskType.CLIP)
            {
                // Turn off caching on mask
                _mask.cacheAsBitmap = false;
                // Save the original filters and clear the filters property
                //originalMaskFilters = _mask.filters;
                _mask.filters = [];
            }
            else if (_maskType == MaskType.ALPHA)
            {
                _mask.cacheAsBitmap = true;
                //notifyElementLayerChanged(); // Trigger recreation of the layers
                displayObject.cacheAsBitmap = true;
            }
        }
    }

    /**
     *  Dispatches a propertyChange event.
     */
    protected function dispatchPropertyChangeEvent(prop:String, oldValue:*,
                                                   value:*):void
    {
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(
                           this, prop, oldValue, value));

    }

    // TODO EGeorgie: can we use the standart IInvalidating methods instead of
    // notifyElementLayerChanged()?
    
    /**
     *  Utility method that notifies our host that we have changed and need
     *  our layer to be updated.
     */
    protected function notifyElementLayerChanged():void
    {
        // TODO EGeorgie: figure this out. For now, invalidateDisplayList
        // to preseve original behavior before layout API unification.
        invalidateDisplayList();
        
        if (elementHost)
            elementHost.elementLayerChanged(this);
    }

    /**
     *  Calling this method results in a call to the elements's
     *  <code>validateProperties()</code> method
     *  before the display list is rendered.
     *
     *  <p>Subclasses should do their work in 
     *  <code>commitProperties()</code>.</p>
     */
    public function invalidateProperties():void
    {
        if (invalidatePropertiesFlag)
            return;
        invalidatePropertiesFlag = true;

        // TODO EGeorgie: hook up directly with the layout manager?
        if (elementHost && elementHost is IInvalidating)
            IInvalidating(elementHost).invalidateProperties();
    }

    /**
     *  Calling this method results in a call to the elements's
     *  <code>validateSize()</code> method
     *  before the display list is rendered.
     *
     *  <p>Subclasses should override and do their measurement in
     *  <code>measure()</code>.
     *  By default when <code>explicitWidth</code> and <code>explicitHeight</code>
     *  are set, <code>measure()</code> will not be called. To override this
     *  default behavior subclasses should override <code>skipMeasure()</code>.</p>
     */
    public function invalidateSize():void
    {
        if (invalidateSizeFlag)
            return;
        invalidateSizeFlag = true;

        // TODO EGeorgie: hook up directly with the layout manager?
        if (elementHost)
            elementHost.elementSizeChanged(this);
    }

    /**
     *  Helper method to invalidate parent size and display list if
     *  this object affects its layout (includeInLayout is true).
     */
    protected function invalidateParentSizeAndDisplayList():void
    {
        if (!includeInLayout)
            return;

        // We want to invalidate both the parent size and parent display list.
        if (elementHost && elementHost is IInvalidating)
        {
            IInvalidating(elementHost).invalidateSize();
            IInvalidating(elementHost).invalidateDisplayList();
        }
    }

    /**
     *  Calling this method results in a call to the elements's
     *  <code>validateDisplayList()</code> method
     *  before the display list is rendered.
     *
     *  <p>Subclasses should override and do their work in
     *  <code>updateDisplayList()</code>.</p>
     */
    public function invalidateDisplayList():void
    {
        if (invalidateDisplayListFlag)
            return;
        invalidateDisplayListFlag = true;

        // TODO EGeorgie: make sure elements that share the display object
        // will be invalidated as well.

        // TODO EGeorgie: hook up directly with the layout manager?
        if (elementHost)
            elementHost.elementChanged(this);
    }

    /**
     *  Validates and updates the properties and layout of this object
     *  by immediately calling <code>validateProperties()</code>,
     *  <code>validateSize()</code>, and <code>validateDisplayList()</code>,
     *  if necessary.
     */
    public function validateNow():void
    {
        if (elementHost)
        {
            UIComponentGlobals.layoutManager.validateClient(
                ILayoutManagerClient(elementHost));
        }
    }

    /**
     *  Used by layout logic to validate the properties of a component
     *  by calling the <code>commitProperties()</code> method.
     *  In general, subclassers should
     *  override the <code>commitProperties()</code> method and not this method.
     */
    public function validateProperties():void
    {
        if (!invalidatePropertiesFlag)
            return;
        commitProperties();
        invalidatePropertiesFlag = false;
        
        // If we aren't doing any more invalidation, send out an UpdateComplete event
        if (!invalidatePropertiesFlag && !invalidateSizeFlag && !invalidateDisplayListFlag)
            dispatchUpdateComplete();        
    }

    /**
     *  Processes the properties set on the element.
     *  This is an advanced method that you might override
     *  when creating a subclass.
     *
     *  <p>You do not call this method directly.
     *  Flex calls the <code>commitProperties()</code> method when you
     *  use the <code>addItem()</code> method to add an element to the group,
     *  or when you call the <code>invalidateProperties()</code> method of the element.
     *  Calls to the <code>commitProperties()</code> method occur before calls to the
     *  <code>measure()</code> method. This lets you set property values that might
     *  be used by the <code>measure()</code> method.</p>
     *
     *  <p>Some elements have properties that
     *  interact with each other.
     *  It is often best at startup time to process all of these
     *  properties at one time to avoid duplicating work.</p>
     */
    protected function commitProperties():void
    {
        //trace("GraphicElement.commitProperties displayObject",displayObject,"this",this);
        var updateTransform:Boolean = false;
        if (displayObject)
        {
            if (alphaChanged)
            {
                alphaChanged = false;
                displayObject.alpha = _alpha;
            }

            if (blendModeChanged)
            {
                blendModeChanged = true;
                displayObject.blendMode = _blendMode;
            }

            if (filtersChanged)
            {
                filtersChanged = false;
                displayObject.filters = _clonedFilters;
            }

            if (maskChanged)
            {
                maskChanged = false;
                if (elementHost)
                {
                    if (previousMask)
                    {
                        elementHost.removeMaskElement(previousMask, this);
                        if (displayObject)
                            displayObject.mask = null;
                    }
                    if (_mask)
                        elementHost.addMaskElement(_mask, this);
                }
            }

            if (maskTypeChanged)
            {
                maskTypeChanged = false;
                applyMaskType();
            }

            if (visibleChanged)
            {
                visibleChanged = false;
                displayObject.visible = _visible;
            }
            
            updateTransform = true;
            displayObjectChanged = false;
        }
        else
        {
            if (visibleChanged)
            {
                visibleChanged = false;
                
                // If we're sharing a display list, we need to force a redraw
                // to change visibility.
                invalidateDisplayList();
            }
        }
        if (layoutFeatures.updatePending ||
            updateTransform)
        {
            applyComputedTransform();
        }
    }

    /**
     *  @inheritDoc
     */
    public function validateSize(recursive:Boolean = false):void
    {
        if (!invalidateSizeFlag)
            return;
        invalidateSizeFlag = false;

        var sizeChanging:Boolean = measureSizes();
                
        if (!sizeChanging || !includeInLayout)
        {
            // If we aren't doing any more invalidation, send out an UpdateComplete event
            if (!invalidatePropertiesFlag && !invalidateSizeFlag && !invalidateDisplayListFlag)
                dispatchUpdateComplete();
            return;
        }

        // Our size has changed, parent has to resize and run layout code
        invalidateParentSizeAndDisplayList();
    }
    
    /**
     *  @return Returns true when the measureSizes() code can skip the call to
     *  measure(). For example this is usually true when both explicitWidth and
     *  explicitHeight are set. For path, this is true when the bounds of the path
     *  have not changed.
     */    
    protected function skipMeasure():Boolean
    {
        return !isNaN(explicitWidth) && !isNaN(explicitHeight);
    }

    /**
     *  @private
     */
    private function measureSizes():Boolean
    {
        var oldWidth:Number = preferredWidthPreTransform();
        var oldHeight:Number = preferredHeightPreTransform();
        var oldX:Number = measuredX;
        var oldY:Number = measuredY;

        if (!skipMeasure())
            measure();

        // Did measure() have effect on preferred size? 
        if (oldWidth != preferredWidthPreTransform() ||
            oldHeight != preferredHeightPreTransform() ||
            oldX != measuredX ||
            oldY != measuredY)
        {
            // Preferred size has changed, layout will be affected.
            return true;
        }

        return false;
    }

    /**
     *  Calculates the default size of the element. This is an advanced
     *  method that you might override when creating a subclass of GraphicElement.
     *
     *  <p>You do not call this method directly. Flex calls the
     *  <code>measure()</code> method when the element is added to a group
     *  using the <code>addItem()</code> method, and when the element's
     *  <code>invalidateSize()</code> method is called. </p>
     *
     *  <p>By default you set both explicit height and explicit width of an element,
     *  Flex does not call the <code>measure()</code> method,
     *  even if you explicitly call the <code>invalidateSize()</code> method.
     *  To override this behavior, override <code>skipMeasure()</code> method.</p>
     *
     *  <p>In your override of this method, you must set the
     *  <code>measuredWidth</code> and <code>measuredHeight</code> properties
     *  to define the default size.
     *  You can optionally set the <code>measuredX</code> and
     *  <code>measuredY</code> properties to define the default measured bounds
     *  top-left corner relative to the origin of the element.</p>
     *
     *  <p>The conceptual point of <code>measure()</code> is for the element to
     *  provide its own natural or intrinsic bounds as a default. Therefore, the
     *  <code>measuredWidth</code> and <code>measuredHeight</code> properties
     *  should be determined by factors such as:</p>
     *  <ul>
     *     <li>The amount of text the component needs to display.</li>
     *     <li>The size of a JPEG image that the component displays.</li>
     *  </ul>
     *
     *  <p>In some cases, there is no intrinsic way to determine default values.
     *  For example, a simple GreenCircle element might simply set
     *  measuredWidth = 100 and measuredHeight = 100 in its <code>measure()</code> method to
     *  provide a reasonable default size. In other cases, such as a TextArea,
     *  an appropriate computation (such as finding the right width and height
     *  that would just display all the text and have the aspect ratio of a Golden Rectangle)
     *  might be too time-consuming to be worthwhile.</p>
     *
     *  <p>The default implementation of <code>measure()</code>
     *  sets the values of the <code>measuredWidth</code>, <code>measuredHeight</code>,
     *  <code>measuredX</code>, and <code>measuredY</code> properties
     *  to <code>0</code>.</p>
     */
    protected function measure():void
    {
        measuredWidth = 0;
        measuredHeight = 0;
        measuredX = 0;
        measuredY = 0;
    }

    /**
     *  @inheritDoc
     */
    public function validateDisplayList():void
    {
        // TODO!!! Turn this off for now because we need to clear all of the DisplayObject
        // graphics and thus need to redraw each graphic element
        // Put this back in once we implement drawingAPI2 
        /* if (!invalidateDisplayListFlag)
            return; */
        invalidateDisplayListFlag = false;

        // we commit our transform in two places. First, during commit properties, because our size depends on it,
        // and our parent will most likely take it into account during layout. Secondly, here, because our parent will likely
        // change our xform as a result of layout, and we need to commit it before we end up on screen.   
        if (layoutFeatures.updatePending)
        {
            applyComputedTransform();
        }
        
        if (visible)
            updateDisplayList(_width, _height);
        
        // If we aren't doing any more invalidation, send out an UpdateComplete event
        if (!invalidatePropertiesFlag && !invalidateSizeFlag && !invalidateDisplayListFlag)
            dispatchUpdateComplete();
    }

    /**
     *  Draws the element and/or sizes and positions its content.
     *  This is an advanced method that you might override
     *  when creating a subclass of GraphicElement.
     *
     *  <p>You do not call this method directly. Flex calls the
     *  <code>updateDisplayList()</code> method when the component is added 
     *  to a group using the <code>addItem()</code> method, and when the element's
     *  <code>invalidateDisplayList()</code> method is called. </p>
     *
     *  <p>This method is where you would do programmatic drawing
     *  using methods on the elements's displayObject
     *  such as <code>graphics.drawRect()</code>.</p>
     *
     *  @param unscaledWidth Specifies the width of the component, in pixels,
     *  in the component's coordinates, regardless of the value of the
     *  <code>scaleX</code> property of the component.
     
     *  @param unscaledHeight Specifies the height of the component, in pixels,
     *  in the component's coordinates, regardless of the value of the
     *  <code>scaleY</code> property of the component.
     */
    protected function updateDisplayList(unscaledWidth:Number,
                                         unscaledHeight:Number):void
    {
    }
    
    /**
     *  @private
     *  Helper function to dispatch the UpdateComplete event 
     */
    private function dispatchUpdateComplete():void
    {
        dispatchEvent(new FlexEvent(FlexEvent.UPDATE_COMPLETE));
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: ILayoutItem
    //
    //--------------------------------------------------------------------------

    /**
     *  @return Returns a reference to the object in the layout tree
     *  represented by this interface.
     */
    public function get target():Object
    {
        return this;
    }

    /**
     *  @return Returns the transformation matrix for this element, or null
     *  if it is detla identity.
     */
    protected function computeMatrix(actualMatrix:Boolean):Matrix
    {
        if (!displayObject)
            return null;
                
        var m:Matrix = layoutFeatures.layoutMatrix;
        return MatrixUtil.isDeltaIdentity(m) ? null : m;
    }

    /**
     *  @return Returns the transformed size. Transformation is this element's
     *  transformation matrix.
     */
    protected function transformSizeForLayout(width:Number, height:Number,
                                              actualMatrix:Boolean):Point
    {
        var size:Point = new Point(width, height);
        var m:Matrix = computeMatrix(actualMatrix);
        if (m)
            size = MatrixUtil.transformSize(size, m);

        // Take stroke into account
        var strokeExtents:Point = getStrokeExtents();
        size.x += strokeExtents.x;
        size.y += strokeExtents.y;
        return size;
    }

    /**
     *  Override for graphic elements that need specific calculation of
     *  coordinates of top-left corner of bounding box when resized to
     *  <code>width</code> and <code>height</code>.
     */
    protected function computeTopLeft(topLeft:Point, width:Number, height:Number, m:Matrix):Point
    {
        MatrixUtil.transformBounds(new Point(_width, _height), m, topLeft);
        return topLeft;
    }

    /**
     *  @private
     */
    private function preferredWidthPreTransform():Number
    {
        return isNaN(explicitWidth) ? measuredWidth : explicitWidth;
    }

    /**
     *  @private
     */
    private function preferredHeightPreTransform():Number
    {
        return isNaN(explicitHeight) ? measuredHeight: explicitHeight;
    }

    /**
     *  <code>setActualPosition</code> moves the item
     *  such that the left-top corner of the item's TBounds
     *  has the specified coordinates.
     */
    public function setActualPosition(x:Number, y:Number):void
    {

        // Take stroke into account:
        // TODO EGeorgie: We assume that the stroke extents are even on both sides.
        // and that's not necessarily true.
        var strokeExtents:Point = getStrokeExtents();
        x += strokeExtents.x * 0.5;
        y += strokeExtents.y * 0.5;

        // Handle arbitrary 2d transform
        var m:Matrix = computeMatrix(true /*actualMatrix*/);
        if (m)
        {
            // Calculate the origin of the element after transformation before our changes are applied.
            var topLeft:Point = computeTopLeft(new Point(measuredX, measuredY), _width, _height, m);

            // now adjust our tx/ty values based on the difference between our current transformed position and 
            // where we want to end up.
            x = x - topLeft.x + layoutFeatures.layoutX;
            y = y - topLeft.y + layoutFeatures.layoutY;
        }
        else
        {
            x -= measuredX;
            y -= measuredY;
        }


        if(x != layoutFeatures.layoutX || y != layoutFeatures.layoutY)
        {
            layoutFeatures.layoutX = x;
            layoutFeatures.layoutY = y;
            // note that we don't want to call invalidateTransform, because 
            // this is in the middle of an update pass. Instead, we just note that the 
            // transform has an update pending, so we can apply it later.
            layoutFeatures.updatePending = true;
            invalidateDisplayList();
        }
    }

    /**
     *  <code>setActualSize</code> modifies the item size/transform
     *  so that its TBounds have the specified <code>width</code>
     *  and <code>height</code>.
     *
     *  If one of the desired TBounds dimensions is left unspecified, it's size
     *  will be picked such that item can be optimally sized to fit the other
     *  TBounds dimension. This is useful when the layout doesn't want to
     *  overconstrain the item in cases where the item TBounds width and height
     *  are dependent (text, components with complex transforms, etc.)
     *
     *  If both TBounds dimensions are left unspecified, the item will have its
     *  preferred size set.
     *
     *  <code>setActualSize</code> does not clip against <code>minSize</code> and
     *  <code>maxSize</code> properties.
     *
     *  <code>setActualSize</code> must preserve the item's TBounds position,
     *  which means that in some cases it will move the item in addition to
     *  changing its size.
     *
     *  @return Returns the TBounds of the new item size.
     */
    public function setActualSize(width:Number = Number.NaN,
                                  height:Number = Number.NaN):Point
    {
        var strokeExtents:Point = getStrokeExtents();

        // Calculate the width and height pre-transform:
        var m:Matrix = computeMatrix(true /*actualMatrix*/);
        if (!m)
        {
            if (isNaN(width))
                width = preferredSize.x;
            if (isNaN(height))
                height = preferredSize.y;

            // Account for stroke
            width -= strokeExtents.x;
            height -= strokeExtents.y;
        }
        else
        {
            if (!isNaN(width))
               width -= strokeExtents.x;

            if (!isNaN(height))
               height -= strokeExtents.y;

            var newSize:Point = MatrixUtil.fitBounds(width, height, m,
                                                     preferredWidthPreTransform(),
                                                     preferredHeightPreTransform(),
                                                     minWidth, minHeight,
                                                     maxWidth, maxHeight);

            if (newSize)
            {
                width = newSize.x;
                height = newSize.y;
            }
            else
            {
                width = minWidth;
                height = minHeight;
            }
        }

        if (_width != width || _height != height)
        {
            var oldWidth:Number = _width;
            var oldHeight:Number = _height;
            
            _width = width;
            _height = height;
            
            dispatchPropertyChangeEvent("width", oldWidth, width);
            dispatchPropertyChangeEvent("height", oldHeight, height);

            invalidateDisplayList();
        }

        return actualSize;
    }

    /**
     *  @private
     */
    private function beginCommitTransformProps():void
    {
        if (_mask && isMaskInElementSpace)
        {
            var maskMatrix:Matrix = _mask.transform.matrix;
            var dispObjMatrix:Matrix = displayObject.transform.matrix.clone();

            dispObjMatrix.invert();
            maskMatrix.concat(dispObjMatrix);
            _mask.transform.matrix = maskMatrix;
            isMaskInElementSpace = false;
        }
    }

    /**
     *  @private
     */
    private function endCommitTransformProps():void
    {
        if (_mask && !isMaskInElementSpace)
        {
            var maskMatrix:Matrix = _mask.transform.matrix;
            maskMatrix.concat(displayObject.transform.matrix);
            _mask.transform.matrix = maskMatrix;
            isMaskInElementSpace = true;
        }
    }

    /**
     *  Applies the transform to the display object.
     */
    protected function applyComputedTransform():void
    {       
        layoutFeatures.updatePending = false;

        if(displayObject == null)
            return;
                    
        if(layoutFeatures.is3D)
        {
            displayObject.transform.matrix3D = layoutFeatures.computedMatrix3D;             
        }
        else
        {
            displayObject.transform.matrix = layoutFeatures.computedMatrix;
        }
        
        if (_colorTransform)
        {
            displayObject.transform.colorTransform = _colorTransform;
        }
    }
    
    /**
     *  @private
     */
    protected function getStroke():IStroke
    {
        return null;
    }

    // TODO EGeorgie: return rectangle instead so that the function can
    // correctly indicate the left, right, top and bottom extents. Right
    // now we assume they are the same on both sides.
    protected function getStrokeExtents():Point
    {
        // TODO EGeorgie: currently we take only scale into account,
        // but depending on joint style, cap style, etc. we need to take
        // the whole matrix into account as well as examine every line segment...
        var stroke:IStroke = getStroke();
        if (!stroke)
           return new Point();

        // Stroke with weight 0 or scaleMode "none" is always drawn
        // at "hairline" thickness, which is exactly one pixel.
        var weight:Number = stroke.weight;
        if (weight == 0)
            return new Point(1, 1);
        var scaleMode:String = stroke.scaleMode;
        if (!scaleMode || scaleMode == LineScaleMode.NONE)
            return new Point(weight, weight);

        // TODO EGeorgie: stroke thickness depends on all matrix components,
        // not only on scale.
        if (scaleMode == LineScaleMode.NORMAL)
        {
            if (layoutFeatures.layoutScaleX == layoutFeatures.layoutScaleY)
                weight *= layoutFeatures.layoutScaleX;
            else
                weight *= Math.sqrt(0.5 * (layoutFeatures.layoutScaleX * layoutFeatures.layoutScaleX + layoutFeatures.layoutScaleY * layoutFeatures.layoutScaleY));
            
            return new Point(weight, weight);
        }
        else if (scaleMode == LineScaleMode.HORIZONTAL)
        {
            return new Point(weight * layoutFeatures.layoutScaleX, weight);
        }
        else if (scaleMode == LineScaleMode.VERTICAL)
        {
            return new Point(weight, weight * layoutFeatures.layoutScaleY);
        }

        return null;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: IConstraintClient
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    public function getConstraintValue(constraintName:String):*
    {
        return this[constraintName];
    }

    /**
     *  @private
     */
    public function setConstraintValue(constraintName:String, value:*):void
    {
        this[constraintName] = value;
    }
    
    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------

    /**
     *  Documentation is not currently available.
     */
    protected function filterChangedHandler(event:Event):void
    {
        filters = _filters;
    }

    /**
     *  Documentation is not currently available.
     */
    protected function transformPropertyChangeHandler(
                                    event:PropertyChangeEvent):void
    {
        if (event.kind == PropertyChangeEventKind.UPDATE)
        {
            if (event.property == "matrix")
            {
                // Apply matrix
                if (_transform)
                {
                    layoutFeatures.layoutMatrix = _transform.matrix.clone();
                    invalidateTransform();
                }
            }
            else if (event.property == "colorTransform")
            {
                // Apply colorTranform
                if (_transform)
                {
                    _colorTransform = _transform.colorTransform;
                    
                    if (displayObject)
                    {
                        displayObject.transform.colorTransform = _colorTransform;
                    }
                    else
                    {
                        invalidateDisplayList();
                        notifyElementLayerChanged();
                    }
                }
            }
        }
    }
}

}
