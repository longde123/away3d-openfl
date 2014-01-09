/**
 * AssetLibrary enforces a singleton pattern and is not intended to be instanced.
 * It's purpose is to allow access to the default library bundle through a set of static shortcut methods.
 * If you are interested in creating multiple library bundles, please use the <code>getBundle()</code> method.
 */
// singleton enforcer
package away3d.library;


import flash.Vector;
import away3d.library.assets.IAsset;
import away3d.library.naming.ConflictStrategyBase;
import away3d.library.utils.AssetLibraryIterator;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.loaders.misc.AssetLoaderToken;
import away3d.loaders.misc.SingleFileLoader;
import away3d.loaders.parsers.ParserBase;
import flash.net.URLRequest;

class AssetLibrary {
    static public var conflictStrategy(get_conflictStrategy, set_conflictStrategy):ConflictStrategyBase;
    static public var conflictPrecedence(get_conflictPrecedence, set_conflictPrecedence):String;

    static private var _instances:Dynamic = { };
/**
	 * Creates a new <code>AssetLibrary</code> object.
	 *
	 * @param se A singleton enforcer for the AssetLibrary ensuring it cannnot be instanced.
	 */

    public function new(se:AssetLibrarySingletonEnforcer) {
        se = se;
    }

/**
	 * Returns an AssetLibrary bundle instance. If no key is given, returns the default bundle (which is
	 * similar to using the AssetLibraryBundle as a singleton). To keep several separated library bundles,
	 * pass a string key to this method to define which bundle should be returned. This is
	 * referred to as using the AssetLibraryBundle as a multiton.
	 *
	 * @param key Defines which multiton instance should be returned.
	 * @return An instance of the asset library
	 */

    static public function getBundle(key:String = "default"):AssetLibraryBundle {
        return AssetLibraryBundle.getInstance(key);
    }

/**
	 *
	 */

    static public function enableParser(parserClass:Class<Dynamic>):Void {
        SingleFileLoader.enableParser(parserClass);
    }

/**
	 *
	 */

    static public function enableParsers(parserClasses:Vector<Class<Dynamic>>):Void {
        SingleFileLoader.enableParsers(parserClasses);
    }

/**
	 * Short-hand for conflictStrategy property on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.conflictStrategy
	 */

    static public function get_conflictStrategy():ConflictStrategyBase {
        return getBundle().conflictStrategy;
    }

    static public function set_conflictStrategy(val:ConflictStrategyBase):ConflictStrategyBase {
        getBundle().conflictStrategy = val;
        return val;
    }

/**
	 * Short-hand for conflictPrecedence property on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.conflictPrecedence
	 */

    static public function get_conflictPrecedence():String {
        return getBundle().conflictPrecedence;
    }

    static public function set_conflictPrecedence(val:String):String {
        getBundle().conflictPrecedence = val;
        return val;
    }

/**
	 * Short-hand for createIterator() method on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.createIterator()
	 */

    static public function createIterator(assetTypeFilter:String = null, namespaceFilter:String = null, filterFunc:Dynamic -> Void = null):AssetLibraryIterator {
        return getBundle().createIterator(assetTypeFilter, namespaceFilter, filterFunc);
    }

/**
	 * Short-hand for load() method on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.load()
	 */

    static public function load(req:URLRequest, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken {
        return getBundle().load(req, context, ns, parser);
    }

/**
	 * Short-hand for loadData() method on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.loadData()
	 */

    static public function loadData(data:Dynamic, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken {
        return getBundle().loadData(data, context, ns, parser);
    }

    static public function stopLoad():Void {
        getBundle().stopAllLoadingSessions();
    }

/**
	 * Short-hand for getAsset() method on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.getAsset()
	 */

    static public function getAsset(name:String, ns:String = null):IAsset {
        return getBundle().getAsset(name, ns);
    }

/**
	 * Short-hand for addEventListener() method on default asset library bundle.
	 */

    static public function addEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
        getBundle().addEventListener(type, listener, useCapture, priority, useWeakReference);
    }

/**
	 * Short-hand for removeEventListener() method on default asset library bundle.
	 */

    static public function removeEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false):Void {
        getBundle().removeEventListener(type, listener, useCapture);
    }

/**
	 * Short-hand for hasEventListener() method on default asset library bundle.
	 */

    static public function hasEventListener(type:String):Bool {
        return getBundle().hasEventListener(type);
    }

    static public function willTrigger(type:String):Bool {
        return getBundle().willTrigger(type);
    }

/**
	 * Short-hand for addAsset() method on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.addAsset()
	 */

    static public function addAsset(asset:IAsset):Void {
        getBundle().addAsset(asset);
    }

/**
	 * Short-hand for removeAsset() method on default asset library bundle.
	 *
	 * @param asset The asset which should be removed from the library.
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.AssetLibraryBundle.removeAsset()
	 */

    static public function removeAsset(asset:IAsset, dispose:Bool = true):Void {
        getBundle().removeAsset(asset, dispose);
    }

/**
	 * Short-hand for removeAssetByName() method on default asset library bundle.
	 *
	 * @param name The name of the asset to be removed.
	 * @param ns The namespace to which the desired asset belongs.
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.AssetLibraryBundle.removeAssetByName()
	 */

    static public function removeAssetByName(name:String, ns:String = null, dispose:Bool = true):IAsset {
        return getBundle().removeAssetByName(name, ns, dispose);
    }

/**
	 * Short-hand for removeAllAssets() method on default asset library bundle.
	 *
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.AssetLibraryBundle.removeAllAssets()
	 */

    static public function removeAllAssets(dispose:Bool = true):Void {
        getBundle().removeAllAssets(dispose);
    }

/**
	 * Short-hand for removeNamespaceAssets() method on default asset library bundle.
	 *
	 * @see away3d.library.AssetLibraryBundle.removeNamespaceAssets()
	 */

    static public function removeNamespaceAssets(ns:String = null, dispose:Bool = true):Void {
        getBundle().removeNamespaceAssets(ns, dispose);
    }

}

class AssetLibrarySingletonEnforcer {

}

