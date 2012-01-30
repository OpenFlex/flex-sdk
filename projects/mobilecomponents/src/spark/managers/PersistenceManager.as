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

package spark.core.managers
{
import flash.net.SharedObject;
    
/**
 *  The PersistenceManager class is a basic persistence manager that 
 *  is backed by a shared object.  When initialized, it will load a
 *  shared object that matches its id.  If one is not found, one will
 *  be created.
 * 
 *  <p>When storing values in the manager, it is important that all
 *  values can be properly be written to a shared object.  Complex
 *  objects that store classes or non-standard flash primitives will
 *  need to implement flash.net.IExternalizable to work properly.
 *  Saving incompatible objects will not cause an RTE, but will create
 *  undefined behavior when read from disk.</p>
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
public class PersistenceManager implements IPersistenceManager
{
    //--------------------------------------------------------------------------
    //
    //  Constants
    //
    //--------------------------------------------------------------------------
    
    private static const SHARED_OBJECT_NAME:String = "FXAppCache";
    
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
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function PersistenceManager()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Variables
    // 
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     *  Returns whether the persistence manager has been initialized.
     */ 
    private var initialized:Boolean = false;
    
    /**
     *  @private
     *  The shared object used by the persistence manager.
     */ 
    private var so:SharedObject;
    
    //--------------------------------------------------------------------------
    //
    //  IPersistenceManager Methods
    // 
    //--------------------------------------------------------------------------
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    public function load():Boolean
    {
        if (initialized)
            return true;
        
        try
        {
            so = SharedObject.getLocal(SHARED_OBJECT_NAME);
            initialized = true;
        }
        catch (e:Error)
        {
            // Fail silently
        }
        
        return initialized;
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    public function setProperty(key:String, value:Object):void
    {
        // If the persistence manager hasn't been initialized, do so now
        if (!initialized)
            load();
        
        // Make sure the shared object is valid since initialization fails silently
        if (so != null)
            so.data[key] = value;
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    public function getProperty(key:String):Object
    {
        // If the persistence manager hasn't been initialized, do so now
        if (!initialized)
            load();
        
        // Make sure the shared object is valid since initialization fails silently
        if (so != null)
            return so.data[key];
        
        return null;
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    public function clear():void
    {
        // If the persistence manager hasn't been initialized, do so now
        if (!initialized)
            load();
        
        // Make sure the shared object is valid since initialization fails silently
        if (so != null)
            so.clear();
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    public function save():Boolean
    {
        try
        {
            // We assume the flush suceeded
            /*var flushStatus:String = */so.flush();
            
            // FIXME (chiedozi): Flush can still fail.  Should validate use case below
//            if (flushStatus == SharedObjectFlushStatus.PENDING)
//                so.addEventListener(NetStatusEvent.NET_STATUS, sharedObject_netStatusHandler);
        }
        catch (e:Error)
        {
            // Fail silently
            return false;
        }
        
        return true;
    }
}
}