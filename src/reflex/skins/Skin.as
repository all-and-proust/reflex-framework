package reflex.skins
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flight.binding.Bind;
	import flight.events.ListEvent;
	import flight.events.ListEventKind;
	import flight.events.PropertyEvent;
	import flight.list.ArrayList;
	import flight.list.IList;
	
	import reflex.components.IStateful;
	import reflex.display.IContainer;
	import reflex.display.addChildAt;
	import reflex.display.addChildrenAt;
	import reflex.events.InvalidationEvent;
	import reflex.layout.LayoutWrapper;
	import reflex.layouts.ILayout;
	import reflex.measurement.resolveHeight;
	import reflex.measurement.resolveWidth;
	
	/**
	 * Skin is a convenient base class for many skins, a swappable graphical
	 * definition. Skins decorate a target Sprite by drawing on its surface,
	 * adding children to the Sprite, or both.
	 */
	[DefaultProperty("children")]
	public class Skin extends EventDispatcher implements ISkin, IContainer, IStateful
	{
		
		static public const MEASURE:String = "measure";
		static public const LAYOUT:String = "layout";
		
		InvalidationEvent.registerPhase(MEASURE, 0, true);
		InvalidationEvent.registerPhase(LAYOUT, 0, true);
		
		private var _layout:ILayout;
		
		[Bindable(event="layoutChange")]
		public function get layout():ILayout { return _layout; }
		public function set layout(value:ILayout):void {
			if(_layout) { _layout.target = null; }
			_layout = value;
			_layout.target = target;
			if(target) {
				InvalidationEvent.invalidate(target, MEASURE);
				InvalidationEvent.invalidate(target, LAYOUT);
			}
		}
		
		private var _currentState:String; [Bindable]
		public function get currentState():String { return _currentState; }
		public function set currentState(value:String):void {
			_currentState = value;
		}
		
		[Bindable]
		public var states:Array;
		
		[Bindable]
		public var transitions:Array;
		
		public function hasState(state:String):Boolean {
			return true;
		}
		
		protected var containerPart:DisplayObjectContainer;
		protected var defaultContainer:Boolean = true;
		private var _target:Sprite;
		private var _children:IList = new ArrayList();
		
		public function Skin()
		{
			_children.addEventListener(ListEvent.LIST_CHANGE, onChildrenChange);
			Bind.addListener(this, onLayoutChange, this, "target.layout");
			Bind.addListener(this, onLayoutChange, this, "layout");
			//Bind.addBinding(this, "data", this, "target.data");
			Bind.addBinding(this, "state", this, "target.state");
			//addEventListener(MEASURE, onMeasure, false, 0, true);
			//addEventListener(LAYOUT, onLayout, false, 0, true);
		}
		
		[Bindable]
		public function get target():Sprite
		{
			return _target;
		}
		public function set target(value:Sprite):void
		{
			if (_target == value) {
				return;
			}
			
			var skinnable:IContainer;
			if (_target != null && _target is IContainer) {
				skinnable = _target as IContainer;
				skinnable.children.removeEventListener(ListEvent.LIST_CHANGE, onContentChange);
				for (var i:int = 0; i < _children.length; i++) {
					_target.removeChild(_children.getItemAt(i) as DisplayObject);
				}
			}
			
			var oldValue:Object = _target;
			_target = value;
			if(layout) {
				layout.target = value;
			}
			if (_target != null) {
				//var i:int;
				/*
				for (i = 0; i < _children.length; i++) {
					_target.addChildAt(_children.getItemAt(i) as DisplayObject, i);
				}*/
				var items:Array = [];
				for (i = 0; i < _children.length; i++) {
					items.push(_children.getItemAt(i));
				}
				reflex.display.addChildrenAt(_target, items, 0);
				/*
				containerPart = getSkinPart("container") as DisplayObjectContainer;
				if (_target is IContainer && containerPart != null) {
					
					skinnable = _target as IContainer;
					skinnable.children.addEventListener(ListEvent.LIST_CHANGE, onContentChange, false, 0xF);
					if (skinnable.children.length > 0) {
						defaultContainer = false;
						Bind.addBinding(containerPart, "padding", this, "target.padding");
						while (containerPart.numChildren) {
							removeContainerChildAt(containerPart.numChildren-1);
						}
						for (i = 0; i < skinnable.children.length; i++) {
							addContainerChildAt(skinnable.children.getItemAt(i) as DisplayObject, i);
						}
					}
				}
				*/
				target.addEventListener("measure", onMeasure, false, 0, true);
				InvalidationEvent.invalidate(target, MEASURE);
				InvalidationEvent.invalidate(target, LAYOUT);
			}
			
			PropertyEvent.dispatchChange(this, "target", oldValue, _target);
			init();
		}
		
		protected function init():void
		{
		}
		
		[ArrayElementType("Object")]
		public function get children():IList
		{
			return _children;
		}
		public function set children(value:*):void
		{
			if (value is DisplayObject) {
				_children.addItem(value);
			} else if (value is Array) {
				_children.removeItems();
				_children.addItems(value);
			} else if (value is IList) {
				_children.addItems( IList(value).getItems() );
			}
		}
		
		public function getSkinPart(part:String):InteractiveObject
		{
			return (part in this) ? this[part] : null;
		}
		
		private function onChildrenChange(event:ListEvent):void
		{
			if (_target == null) {
				return;
			}
			var child:DisplayObject;
			var loc:int = event.location1;
			switch (event.kind) {
				case ListEventKind.ADD :
					/*
					for each (child in event.items) {
						_target.addChildAt(child, loc++);
					}*/
					reflex.display.addChildrenAt(_target, event.items, loc++);
					break;
				case ListEventKind.REMOVE :
					for each (child in event.items) {
					_target.removeChild(child);
					}
					break;
				case ListEventKind.REPLACE :
					_target.removeChild(event.items[1]);
					_target.addChildAt(event.items[0], loc);
					break;
				case ListEventKind.RESET :
					while (_target.numChildren) {
						_target.removeChildAt(_target.numChildren-1);
					}/*
					for (var i:int = 0; i < _children.length; i++) {
						_target.addChildAt(_children.getItemAt(i) as DisplayObject, i);
					}*/
					reflex.display.addChildrenAt(_target, event.items, 0);
					break;
			}
		}
		
		private function onContentChange(event:ListEvent):void
		{
			event.stopImmediatePropagation();
			var skinnable:IContainer = _target as IContainer;
			if (defaultContainer) {
				defaultContainer = false;
				Bind.addBinding(containerPart, "padding", this, "target.padding");
				while (containerPart.numChildren) {
					removeContainerChildAt(containerPart.numChildren-1);
				}
			}
			
			var child:DisplayObject;
			var loc:int = event.location1;
			switch (event.kind) {
				case ListEventKind.ADD :
					for each (child in event.items) {
					//addContainerChildAt(child, loc++);
					addChildAt(target, child, loc++);
				}
					break;
				case ListEventKind.REMOVE :
					for each (child in event.items) {
					removeContainerChild(child);
				}
					break;
				case ListEventKind.REPLACE :
					removeContainerChild(event.items[1]);
					addContainerChildAt(event.items[0], loc);
					break;
				case ListEventKind.RESET :
					while (containerPart.numChildren) {
						removeContainerChildAt(containerPart.numChildren-1);
					}
					
					for (var i:int = 0; i < skinnable.children.length; i++) {
						addContainerChildAt(skinnable.children.getItemAt(i) as DisplayObject, i);
					}
					break;
			}
			
			trace("invalidate");
			/*
			var containerLayout:LayoutWrapper = LayoutWrapper.getLayout(containerPart);
			if (containerLayout != null) {
				containerLayout.invalidate(true);
			}*/
		}
		
		protected function addContainerChildAt(child:DisplayObject, index:int):DisplayObject
		{
			if (containerPart is IContainer) {
				return IContainer(containerPart).children.addItemAt(child, index) as DisplayObject;
			} else {
				return containerPart.addChildAt(child, index);
			}
		}
		
		protected function removeContainerChildAt(index:int):DisplayObject
		{
			if (containerPart is IContainer) {
				return IContainer(containerPart).children.removeItemAt(index) as DisplayObject;
			} else {
				return containerPart.removeChildAt(index);
			}
		}
		
		protected function removeContainerChild(child:DisplayObject):DisplayObject
		{
			if (containerPart is IContainer) {
				return IContainer(containerPart).children.removeItem(child) as DisplayObject;
			} else {
				return containerPart.removeChild(child);
			}
		}
		
		private function onLayoutChange(value:ILayout):void
		{
			if (_target == null) {
				return;
			}
			/*
			var targetLayout:LayoutWrapper = LayoutWrapper.getLayout(_target);
			
			if (containerPart != null && _target is IContainer) {
				var skinnable:IContainer = _target as IContainer;
				var containerLayout:LayoutWrapper = LayoutWrapper.getLayout(containerPart);
				if (containerLayout != null) {
					//containerLayout.algorithm = skinnable.layout;
				} else if (targetLayout != null) {
					containerLayout = new targetLayout["constructor"]();
					containerLayout.target = containerPart;
					//containerLayout.algorithm = skinnable.layout;
				}
			}
			
			if (targetLayout != null) {
				//targetLayout.algorithm = layout;
			}*/
			
		}
		
		private function onMeasure(event:InvalidationEvent):void {
			var target:Object = this.target as Object;
			if(layout && (isNaN(target.measurements.expliciteWidth) || isNaN(target.measurements.expliciteHeight))) {
				var items:Array = [];
				var length:int = _children.length;
				for(var i:int = 0; i < length; i++) {
					items.push(_children.getItemAt(i));
				}
				var point:Point = layout.measure(items);
				target.measurements.measuredWidth = point.x;
				target.measurements.measuredHeight = point.y;
				InvalidationEvent.invalidate(this.target, LAYOUT);
			}
		}
		
		private function onLayout(event:InvalidationEvent):void {
			var items:Array = [];
			var length:int = _children.length;
			for(var i:int = 0; i < length; i++) {
				items.push(_children.getItemAt(i));
			}
			var rectangle:Rectangle = new Rectangle(0, 0, resolveWidth(target), resolveHeight(target));
			layout.update(items, rectangle);
		}
		
	}
}
