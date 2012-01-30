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

package spark.components.supportClasses
{
import flash.desktop.NativeApplication;
import flash.display.InteractiveObject;
import flash.display.StageOrientation;
import flash.events.Event;
import flash.events.InvokeEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.StageOrientationEvent;
import flash.net.registerClassAlias;
import flash.system.Capabilities;
import flash.ui.Keyboard;

import mx.core.IFactory;
import mx.core.mx_internal;
import mx.events.FlexEvent;
import mx.events.FlexMouseEvent;
import mx.events.ResizeEvent;

import spark.components.Application;
import spark.components.View;
import spark.components.ViewMenu;
import spark.components.ViewMenuItem;
import spark.core.managers.IPersistenceManager;
import spark.core.managers.PersistenceManager;
import spark.events.PopUpEvent;

[Exclude(name="controlBarContent", kind="property")]
[Exclude(name="controlBarGroup", kind="property")]
[Exclude(name="controlBarLayout", kind="property")]
[Exclude(name="controlBarVisible", kind="property")]
[Exclude(name="layout", kind="property")]
[Exclude(name="preloaderChromeColor", kind="property")]
[Exclude(name="backgroundAlpha", kind="style")]

use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  This cancelable event dispatched before the application attempts
 *  to restore its previously saved state when the application is being 
 *  launched.  Calling <code>preventDefault</code> on this event will 
 *  prevent the application state from being restored.
 * 
 *  @eventType mx.events.FlexEvent.NAVIGATOR_STATE_LOADING
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10.1
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
[Event(name="navigatorStateLoading", type="mx.events.FlexEvent")]

/**
 *  This cancelable event dispatched before the application attempts
 *  to persist its state when the application being suspended or exitted.
 *  Calling <code>preventDefault</code> on this event will prevent the
 *  application state from being saved.
 * 
 *  @eventType mx.events.FlexEvent.NAVIGATOR_STATE_SAVING
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10.1
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
[Event(name="navigatorStateSaving", type="mx.events.FlexEvent")]

/**
 *  The base application class used for all view based application types.
 *  This includes MobileApplication and TabbedMobileApplication.  This class
 *  provides the basic infrastructure for providing these types of applications
 *  access to the device application menu, hardware keys, orientation status
 *  and application session persistence.
 *  
 *  @see spark.components.MobileApplication
 *  @see spark.components.TabbedMobileApplication
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10.1
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
public class MobileApplicationBase extends Application
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Constructor
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    public function MobileApplicationBase()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Skin Parts
    //
    //--------------------------------------------------------------------------
    
    [SkinPart(required="false")]
    /**
     *  Dynamic skin part that defines the ViewMenu used to display the
     *  view menu when the menu button is pressed. The default skin uses 
     *  a factory that generates an ViewMenu instance. 
     */ 
    public var viewMenu:IFactory;
    
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     *  Provides access to the active view of the current navigator. This was
     *  added to provide the ViewMenu access to the active view's viewMenuItems 
     *  property.
     */ 
    mx_internal function get activeView():View
    {
        return null;
    }
    
    /**
     *  @private
     *  This flag indicates when a user has called preventDefault on the
     *  KeyboardEvent dispatched when the back key is pressed.
     */
    private var backKeyEventPreventDefaulted:Boolean = false;
    
    /**
     *  @private
     */
    private var currentViewMenu:ViewMenu;
    
    /**
     *  @private
     *  This property is used to determine whether the application should 
     *  exit when the back key is pressed.
     *
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    mx_internal function get exitApplicationOnBackKey():Boolean
    {
        return true;   
    }
    
    /**
     *  @private
     */ 
    private var lastFocus:InteractiveObject;
    
    /**
     *  @private
     *  This flag indicates when a user has called preventDefault on the
     *  KeyboardEvent dispatched when the menu key is pressed.
     */
    private var menuKeyEventPreventDefaulted:Boolean = false;
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  persistenceManager
    //----------------------------------
    private var _persistenceManager:IPersistenceManager;
    
    /**
     *  The persistenceManager for the application.  The persistence
     *  manager is automatically created on demand when accessed for the
     *  first time.  Override the <code>createPersistenceManager()</code>
     *  method to change the type of persistence manager that is created.
     * 
     *  <p>The persistence manager will automatically save and restore
     *  the main navigator's persistence stack if the
     *  <code>persistNavigatorState</code> flag is set to true. Data stored 
     *  in the persistence manager will automatically be flushed to disk 
     *  when the application is suspended or exited.</p>
     *  
     *  <p>The default implementation of the persistence manager uses
     *  a shared object as it's backing data store.  All information that is
     *  saved to this object must adhere to flash AMF rules for object encoding.
     *  This means that custom classes will need to be registered through the use
     *  of <code>flash.net.registerClassAlias</code></p>
     * 
     *  @default Instance of a spark.core.managers.PersistenceManager
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get persistenceManager():IPersistenceManager
    {
        if (!_persistenceManager)
        {
            _persistenceManager = createPersistenceManager();
        }
        
        return _persistenceManager;
    }
    
    //----------------------------------
    //  persistNavigatorState
    //----------------------------------
    
    private var _persistNavigatorState:Boolean = false;
    
    /**
     *  Toggles the application session caching feature for the application.  When
     *  enabled, the application will automatically save the main navigator's view 
     *  data and navigation history to the persistence manager.  When the application 
     *  is relaunched, this data will automatically be read from the persistence store
     *  and applied to the application's navigator.
     * 
     *  <p>When enabled, the application version and time the persistence data was 
     *  generated will also be added to the persistence object.  These can be
     *  accessed by using the persistence manager's <code>getProperty()</code> method
     *  using either the <code>applicationVersion</code> or <code>timestamp</code> key.</p>
     * 
     *  <p>When the persistence object is being created, the application will dispatch
     *  a cancelable <code>FlexEvent.APPLICATION_PERSISTING</code> event when the process
     *  begins and a <code>FlexEvent.APPLICATION_PERSIST</code> event when it completes.  
     *  If the APPLICATION_PERSISTING event is canceled, the persistence object is not created.
     *  Similarily, when this information is being restored to the application, a cancelable
     *  <code>FlexEvent.APPLICATION_RESTORING</code> is dispatched followed by a
     *  <code>FlexEvent.APPLICATION_RESTORE</code> event.  Canceling the APPLICATION_RESTORING
     *  event will prevent the navigation data from being restored.</p>
     * 
     *  <p>The <code>persistNavigatorState</code> flag must be set to true before
     *  the application initializes itself for the navigator's state to be automatically
     *  restored.</p>
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get persistNavigatorState():Boolean
    {
        return _persistNavigatorState;
    }
    
    /**
     * @private
     */ 
    public function set persistNavigatorState(value:Boolean):void
    {
        _persistNavigatorState = value;
    }
    
    //----------------------------------
    //  viewMenuOpen
    //----------------------------------
    
    /**
     *  Opens the view menu if set to true and closes it if set to false. 
     * 
     *  @default false
     */
    public function get viewMenuOpen():Boolean
    {
        return currentViewMenu && currentViewMenu.isOpen;
    }
    
    /**
     *  @private
     */ 
    public function set viewMenuOpen(value:Boolean):void
    {
        if (value == viewMenuOpen)
            return;
        
        if (!viewMenu || !activeView.viewMenuItems || activeView.viewMenuItems.length == 0)
            return;
        
        if (value)
            openViewMenu();
        else
            closeViewMenu();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  This method is called when the application is invoked by the
     *  OS.  This method is called in response to a InvokeEvent.INVOKE
     *  event.
     * 
     *  @param event The InvokeEvent object
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */  
    protected function invokeHandler(event:InvokeEvent):void
    {
    }
    
    /**
     *  This method is called when the application is exiting or being
     *  sent to the background by the OS.  If <code>persistNavigatorState</code>
     *  is set to true, the application will begin the state saving process
     *  here.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    protected function deactivateHandler(event:Event):void
    {
        // Check if the application state should be persisted 
        if (persistNavigatorState)
        {
            // Dispatch event for saving persistence data
            var eventCanceled:Boolean = false;
            if (hasEventListener(FlexEvent.NAVIGATOR_STATE_SAVING))
                eventCanceled = !dispatchEvent(new FlexEvent(FlexEvent.NAVIGATOR_STATE_SAVING, 
                                                                false, true));
            
            if (!eventCanceled)
            {
                saveNavigatorState();
            }
        }

        // Always flush the persistence manager to disk if it exists
        if (_persistenceManager)
        {
            persistenceManager.save();
        }
    }
    
    /**
     *  This method is called when the Application's hardware back key is pressed
     *  by the user.
     *   
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    protected function backKeyUpHandler(event:KeyboardEvent):void
    {
    }
    
    /**
     *  Called when the menu key is pressed. By default, this opens or closes
     *  the ViewMenu. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    protected function menuKeyUpHandler(event:KeyboardEvent):void
    {
        if (activeView && !activeView.menuKeyHandledByView())
            viewMenuOpen = !viewMenuOpen;
    }
    
    /**
     *  Method is responsible for create the persistence manager for the application.
     *  This method will automatically be called when the persistence manager is
     *  accessed for the first time or if the <code>persistNavigatorState</code> flag
     *  is set to true on the application.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    protected function createPersistenceManager():IPersistenceManager
    {
        return new PersistenceManager();
    }
    
    /**
     *  Responsible for persisting the application state to the persistence manager.
     *  This method is automatically called when <code>persistNavigatorState</code>
     *  is set to true.  By default, this method will save the application version 
     *  and the time the persistence object was created to the "timestamp" and 
     *  "applicationVersion" keys.
     * 
     *  <p>This method will only be called if the <code>FlexEvent.APPLICATION_PERSISTING</code>
     *  event is not canceled.</p>
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    protected function saveNavigatorState():void
    {
        // Save version number of application
        var appDescriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
        var ns:Namespace = appDescriptor.namespace();
        
        persistenceManager.setProperty("versionNumber", 
                                        appDescriptor.ns::versionNumber.toString());
    }
    
    /**
     *  Responsible for restoring the application's state when the
     *  <code>persistNavigatorState</code> flag is set to true.
     * 
     *  <p>This method will only be called if the <code>FlexEvent.APPLICATION_RESTORING</code>
     *  event is not canceled.</p>
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    protected function loadNavigatorState():void
    {
    }
    
    //--------------------------------------------------------------------------
    //
    //  Private Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    private function addApplicationListeners():void
    {
        // Add device event listeners
        systemManager.stage.addEventListener(KeyboardEvent.KEY_DOWN, deviceKeyDownHandler);
        systemManager.stage.addEventListener(KeyboardEvent.KEY_UP, deviceKeyUpHandler);
        systemManager.stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, 
            orientationChangeHandler);
        NativeApplication.nativeApplication.
            addEventListener(InvokeEvent.INVOKE, invokeHandler);
        
        // We need to listen to different events on desktop and mobile because
        // on desktop, the deactivate event is dispatched whenever the window loses
        // focus.  This could cause persistence to run when the developer doesn't
        // expect it to on desktop.
        var os:String = Capabilities.os;
        
        // FIXME (chiedozi): enumerate all possible os values
        if (os.indexOf("Windows") != -1 || os.indexOf("Mac OS") != -1)
            NativeApplication.nativeApplication.
                addEventListener(Event.EXITING, deactivateHandler);
        else
            NativeApplication.nativeApplication.
                addEventListener(Event.DEACTIVATE, deactivateHandler);
    }
    
    /**
     *  @private
     *  The key model employeed by MobileApplication is to listen for the down
     *  event but run the back key handling logic on up.  The reasoning for this
     *  is that the down event is dispatched multiple times while the user
     *  presses it down.  But the desired back logic should only happen once.
     *  So when a down event is received, the application only tracks if it has been
     *  canceled by the developer.
     * 
     *  It is still necessary to listen to the down key because the application
     *  needs to cancel the device's default back logic at this stage.  For example,
     *  on android, when the back key is pressed, the default behavior is to
     *  suspend the application and return to the home screen.  This functionality
     *  can only be canceled when the down event is received.
     */ 
    private function deviceKeyDownHandler(event:KeyboardEvent):void
    {
        var key:uint = event.keyCode;
        
        // We want to prevent the default down behavior for back key if 
        // the navigator has a view to pop back to
        if (key == Keyboard.BACK)
        {
            backKeyEventPreventDefaulted = event.isDefaultPrevented();
            
            if (!exitApplicationOnBackKey)
                event.preventDefault();
        }
        else if (key == Keyboard.MENU)
        {
            menuKeyEventPreventDefaulted = event.isDefaultPrevented();
        }
    }
    
    /**
     *  @private
     */ 
    private function deviceKeyUpHandler(event:KeyboardEvent):void
    {
        var key:uint = event.keyCode;

        // If preventDefault() wasn't called on the initial keyDown event
        // and the application thinks it can cancel the native back behavior,
        // call the backKeyHandler() method.  Otherwise, the runtime will
        // handle the back key function.
        
        // The backKeyEventPreventDefaulted key is always set in the
        // deviceKeyDownHandler method and so doesn't need to be reset.
        if (key == Keyboard.BACK && !backKeyEventPreventDefaulted && !exitApplicationOnBackKey)
            backKeyUpHandler(event);
        else if (key == Keyboard.MENU && !menuKeyEventPreventDefaulted)
            menuKeyUpHandler(event);
    }
    
    /**
     *  @private
     */  
    private function orientationChangeHandler(event:StageOrientationEvent):void
    {   
        if (currentViewMenu)
        {
            // Update size, the position stays at (0,0)
            currentViewMenu.width = getLayoutBoundsWidth();
            currentViewMenu.height = getLayoutBoundsHeight();
        }
    } 

    /**
     *  @private
     */ 
    private function viewMenu_clickHandler(event:MouseEvent):void
    {
        if (event.target is ViewMenuItem)
            viewMenuOpen = false;
    }
    
    /**
     *  @private
     */ 
    private function viewMenu_mouseDownOutsideHandler(event:FlexMouseEvent):void
    {
        viewMenuOpen = false;
    }
    
    /**
     *  @private
     */ 
    private function openViewMenu():void
    {
        if (!currentViewMenu)
        {
            currentViewMenu = ViewMenu(viewMenu.newInstance());
            currentViewMenu.items = activeView.viewMenuItems;
            
            // Size the menu as big as the app
            currentViewMenu.width = getLayoutBoundsWidth();
            currentViewMenu.height = getLayoutBoundsHeight();
            
            // Remember the focus, we'll restore it when the menu closes
            lastFocus = getFocus();
            currentViewMenu.setFocus();
            
            currentViewMenu.addEventListener(MouseEvent.CLICK, viewMenu_clickHandler);
            currentViewMenu.addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, viewMenu_mouseDownOutsideHandler);
            currentViewMenu.addEventListener(PopUpEvent.CLOSE, viewMenuClose_handler);
            currentViewMenu.addEventListener(PopUpEvent.OPEN, viewMenuOpen_handler);
            addEventListener(ResizeEvent.RESIZE, resizeHandler);
        }
        
        currentViewMenu.open(this, false /*modal*/);
    }

    /**
     *  @private
     */ 
    private function closeViewMenu():void
    {
        if (currentViewMenu)
            currentViewMenu.close();
    }
    
    /**
     *  @private
     */ 
    private function viewMenuOpen_handler(event:PopUpEvent):void
    {
        // Private event for testing
        if (activeView.hasEventListener("viewMenuOpen"))
            activeView.dispatchEvent(new Event("viewMenuOpen"));
    }

    /**
     *  @private
     */ 
    private function viewMenuClose_handler(event:PopUpEvent):void
    {
        currentViewMenu.removeEventListener(PopUpEvent.OPEN, viewMenuOpen_handler);
        currentViewMenu.removeEventListener(PopUpEvent.CLOSE, viewMenuClose_handler);
        currentViewMenu.removeEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, viewMenu_mouseDownOutsideHandler);
        currentViewMenu.removeEventListener(MouseEvent.CLICK, viewMenu_clickHandler);
        removeEventListener(ResizeEvent.RESIZE, resizeHandler);
        
        // Private event for testing
        if (activeView.hasEventListener("viewMenuClose"))
            activeView.dispatchEvent(new Event("viewMenuClose"));
        
        // Clear the caret and validate properties to put back the viewMenu items
        // in their default state so that next time we open the menu we don't
        // see an item in a stale "caret" state.
        currentViewMenu.caretIndex = -1;
        currentViewMenu.validateProperties();
        
        currentViewMenu.items = null;
        currentViewMenu = null;
        
        // Restore focus
        systemManager.stage.focus = lastFocus;
    }
    
    private function resizeHandler(event:ResizeEvent):void
    {
        // Size the menu as big as the app
        currentViewMenu.width = getLayoutBoundsWidth();
        currentViewMenu.height = getLayoutBoundsHeight();
        currentViewMenu.invalidateSkinState();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private 
     */ 
    override public function initialize():void
    {
        super.initialize();
        
        addApplicationListeners();
        
        if (persistNavigatorState)
        {
            // Register aliases for custom classes that will be written to
            // persistence store by navigator
            registerClassAlias("ViewDescriptor", ViewDescriptor);
            registerClassAlias("NavigationStack", NavigationStack);
            
            persistenceManager.load();
            
            // Dispatch event for loading persistence data
            var eventDispatched:Boolean = true;
            if (hasEventListener(FlexEvent.NAVIGATOR_STATE_LOADING))
                eventDispatched = dispatchEvent(new FlexEvent(FlexEvent.NAVIGATOR_STATE_LOADING, 
                                                false, true));
            
            if (eventDispatched)
            {
                loadNavigatorState();
            }
        } 
    }
}
}







