﻿/** * <p>Original Author: Daniel Freeman</p> * * <p>Permission is hereby granted, free of charge, to any person obtaining a copy * of this software and associated documentation files (the "Software"), to deal * in the Software without restriction, including without limitation the rights * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell * copies of the Software, and to permit persons to whom the Software is * furnished to do so, subject to the following conditions:</p> * * <p>The above copyright notice and this permission notice shall be included in * all copies or substantial portions of the Software.</p> * * <p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN * THE SOFTWARE.</p> * * <p>Licensed under The MIT License</p> * <p>Redistributions of files must retain the above copyright notice.</p> */package com.danielfreeman.madcomponents {			import flash.display.DisplayObject;		import flash.display.DisplayObjectContainer;		import flash.display.GradientType;		import flash.display.SpreadMethod;		import flash.display.Sprite;		import flash.display.Shape;		import flash.events.Event;		import flash.events.MouseEvent;		import flash.geom.Matrix;		import flash.geom.Rectangle;		import flash.text.TextFieldAutoSize;		import flash.text.TextFormat;		import flash.utils.getDefinitionByName;

/** * A clickable group was pressed */		[Event( name="groupClicked", type="flash.events.Event" )]/** * Clickable group pressed highlight cleared */		[Event( name="groupClickedEnd", type="flash.events.Event" )]				/** * A lazyRendered form has loaded */		[Event( name="lazyLoad", type="flash.events.Event" )]		/** * A lazyRendered form has unloaded */		[Event( name="lazyUnload", type="flash.events.Event" )]		/** * UIForm is for horizontal, vertical, group, clickableGroup, columns, rows, and frame containers * <pre> * &lt;horizontal|vertical|columns|rows|group|clickableGroup|frame *    id = "IDENTIFIER" *    colour = "#rrggbb" *    background = "#rrggbb, #rrggbb, ..." *    gapV = "NUMBER" *    gapH = "NUMBER" *    alignH = "left|right|centre|fill" *    alignV = "top|bottom|centre|fill" *    visible = "true|false" *    lines = "true|false" *    widths = "i(%),j(%),k(%)…" *    heights = "i(%),j(%),k(%)…" *    pickerHeight = "NUMBER" *    border = "true|false" *    autoLayout = "true|false" *    lazyRender = "true|false" * /&gt; * </pre> * */			public class UIForm extends MadMasking implements IContainerUI {						public static const CLICKED:String = "groupClicked";			public static const CLICKED_END:String = "groupClickedEnd";			public static const LOADED:String = "lazyLoad";			public static const UNLOADED:String = "lazyUnload";								protected static const DEFAULT_INPUT_WIDTH:Number = 100.0;			protected static const LINE_COLOUR:uint = 0x999999;			protected static const CELL_COLOUR:uint = 0xFFFFFF;			protected static const CURVE:Number = 8.0;			protected static const GROUP_OFFSET:Number = -1;			protected static const TWEAK:Number = 10.0;						protected var _mode:String = "";			protected var _model:Model = null;			protected var _height:Number = -1;			protected var _children:Array;			protected var _row:Boolean;						protected var _widths:Array = null;			protected var _heights:Array = null;			protected var _autoLayout:Boolean = false;			protected var _pickerHeight:Number = -1;			protected var _cursorHeight:Number = -1;			protected var _extra:Number = 0;			protected var _style:Sprite = null;						protected var _groups:Array = null;			protected var _index:int = -1;						protected var _insideScroller:Boolean = false;			protected var _lines:Boolean = false;			protected var _positions:Array = [];						protected var _inGroup:Boolean = false;			protected var _disable:Array = [];			protected var _lazyRender:Boolean = false;			protected var _recycle:Boolean = false;			protected var _localName:String;						protected var _pickerBackground:Boolean = false;			protected var _padding:Number = UI.PADDING;			public function UIForm(screen:Sprite, xml:XML, attributes:Attributes = null, row:Boolean = false, inGroup:Boolean = false) {				screen.addChild(this);				_inGroup = inGroup;				_row = row;				_localName = (xml.localName().indexOf("Horizontal")>0) ? "horizontal" : xml.localName();							//	_border = xml.@border.length()==0 || xml.@border[0]!="false";								if (_inGroup && (_localName=="horizontal" || _localName=="columns"))					_row = true;								if (xml.@pickerHeight.length() > 0) {					_pickerHeight = parseFloat(xml.@pickerHeight);				}				if (xml.@cursorHeight.length() > 0) {					_cursorHeight = parseFloat(xml.@cursorHeight);				}				if (xml.@pickerPadding.length() > 0) {					_padding = parseFloat(xml.@pickerPadding);				}								if (_localName=="group" || _localName=="clickableGroup") {					addChild(_style = new Sprite());					if (_localName=="clickableGroup") {						_groups = [];						addEventListener(MouseEvent.MOUSE_DOWN, groupClicked);					}					_localName = "vertical";					if (xml.@lines.length()>0 && xml.@lines[0].toString()!="false") {						_lines=true;					}					_inGroup = true;				}								_lazyRender = xml.@lazyRender=="true";				_recycle = xml.@recycle=="true" && _lazyRender;							//	_xml = xml;			//	_attributes = attributes; //.copy(_xml);				super(xml, attributes);								if (_style || !_attributes.hasBorder && xml.@border.length()>0 && xml.@border[0]!="false") {					_attributes.y = UI.PADDING + _attributes.paddingV/2;					_attributes.x += UI.PADDING;					_attributes.width -= 2*UI.PADDING;					_attributes.height -= 2*UI.PADDING + _attributes.paddingV;					_attributes.hasBorder = true;				}				if (!_lazyRender) {					parseBlock(xml, _attributes, _localName, _row);				}								graphics.beginFill(0, 0); //Quick fix				graphics.drawRect(0, 0, 2, 2);								if (xml.model.length()>0 || xml.sendModel.length()>0) {					_model = new UI.ModelClass(this, xml.model[0], xml.sendModel[0]);				}				if (_localName!="scrollVertical" && xml.@autoLayout.length()>0 && xml.@autoLayout[0]!="false") {					_autoLayout = true;					addEventListener(UIImageLoader.LOADED, doLayoutHandler);				}			}									protected function reset():void {				_mode = "";				_height = -1;				_widths = null;				_heights = null;				_index = -1;				_positions = [];				_disable = [];			}			/** *  Pass an array of row indexes to disable group rows */				public function disableClickableGroupRows(value:Array):void {				_disable = value;			}/** *  If this container is inside a scrolling container, you would call this method */				public function insideScroller():void {				_insideScroller = true;			}									public function get attributes():Attributes {				return _attributes;			}									public function get xml():XML {				return _xml;			}									public function set xml(value:XML):void {				UI.clear(this);				reset();				_xml = XML("<form>"+value+"</form>");				if (!_lazyRender) {					parseBlock(_xml, _attributes, _localName, _row);				}			}									public function includeComponent(id:String, state:Boolean):void {				var child:DisplayObject = findViewById(id);				if (child is MadSprite)					MadSprite(child).includeInLayout = child.visible = state;				layout(_attributes);			}									protected function customWidths():Boolean {				if (_xml.@widths.length() > 0) {					_widths = _xml.@widths.toString().split(",");					var total:Number = (_xml.children().length() - 1) * _attributes.paddingH;					for each (var item : String in _widths)						if (item.lastIndexOf("%")<0)							total+=parseInt(item);					for (var i:int = 0; i<_widths.length; i++) {						var itemi:String = _widths[i];						if (itemi.lastIndexOf("%")>0)							_widths[i] = parseInt(itemi)/100 * (_attributes.width - total);					}						}				return _widths!=null;			}									protected function customHeights():Boolean {				if (_xml.@heights.length() > 0) {					_heights = _xml.@heights.toString().split(",");					var total:Number = (_xml.children().length() - 1) * _attributes.paddingV;					for each (var item : String in _heights)					if (item.lastIndexOf("%")<0)						total+=parseInt(item);					for (var i:int = 0; i<_heights.length; i++) {						var itemi:String = _heights[i];						if (itemi.lastIndexOf("%")>0)							_heights[i] = parseInt(itemi)/100 * (_attributes.height - total);					}						}				return _heights!=null;			}			/** *  Parse the XML, adding child UI components to this container */				protected function parseBlock(xml:XML, attributes:Attributes, mode:String, row:Boolean):DisplayObject {								attributes.parse(xml);								if (xml.@width.length()>0)					attributes.width = xml.@width[0];								if (xml.@height.length()>0)					attributes.height = xml.@height[0];								if (xml.@widths.length()>0)					mode = "columns";				else if (xml.@heights.length()>0)					mode = "rows";				var xmlList:XMLList = xml.children();				var nColumns:int = numberOfColumns(xmlList);				var pos:Number = ((mode=="vertical" || mode=="rows" || mode.indexOf("Panel")>=0 || mode.indexOf("scroll")>=0) ? attributes.y : attributes.x);				var columnWidth:Number = (attributes.width - (nColumns - 1) * attributes.paddingH) / nColumns;				var columnHeight:Number = (attributes.height - (nColumns - 1) * attributes.paddingV) / nColumns;				var hasPicker:Boolean = false;				_xml = xml;				_attributes = attributes;				_mode = mode;								_children = [];				var col:int = 0;				for (var l:int=0;l<xmlList.length();l++) {					var line:XML=xmlList[l];					var localName:String = line.localName();										if (line.nodeKind() == "text" || localName=="data" || localName=="model" || localName=="sendModel")						continue;											var child:DisplayObject;					var childAttributes:Attributes = attributes.copy(line, true);					childAttributes.y = 0;										if (mode=="columns") {						if (customWidths()) {							childAttributes.width = columnWidth = _widths[col];							childAttributes.x = pos;													}						else {							childAttributes.width = columnWidth;							childAttributes.x = pos;						}					}					else if (mode=="rows") {						if (customHeights()) {							childAttributes.height = columnHeight = _heights[col];							childAttributes.y = pos;													}						else {							childAttributes.height = columnHeight;							childAttributes.y = pos;						}					} else if (mode=="horizontal") {						childAttributes.width += (childAttributes.x-pos);						if (childAttributes.width < 0)							childAttributes.width = 0;						childAttributes.x = pos;					}					else if (mode!="frame") {						childAttributes.height += (childAttributes.y-pos);						if (childAttributes.height < 0)							childAttributes.height = 0;						childAttributes.y = pos;					}					child = UI.containers(this, line, childAttributes);					if (!child)					switch(localName) {						case 'group':						case 'clickableGroup': 						case 'frame':						case 'horizontal':						case 'vertical':						case 'rows':						case 'columns': var newAttributes:Attributes = childAttributes.copy();											newAttributes.x=0;											newAttributes.y=0;								//			if (localName=="rows" || localName=="columns")								//				newAttributes.hasBorder = false;									child = new UI.FormClass(this, line, newAttributes, row, _inGroup);									break;						case 'search':child = new UISearch(this, line, childAttributes);break;						case 'imageLoader':child = new UIImageLoader(this, line, childAttributes);break;						case 'picker':child = new UIPicker(this, line, childAttributes,mode!="columns" || l==0,mode!="columns" || l==xmlList.length()-1, _pickerHeight,_cursorHeight);							hasPicker = true;							break;						case 'label':child = parseLabel(line, childAttributes);break;						case 'button':child = parseButton(line, childAttributes);break;						case 'image':child = new UIImage(this, line, childAttributes);break;						case 'input':child = parseInput(line, childAttributes);break;						case 'switch':child = parseSwitch(line, childAttributes);break;						case 'slider':child = parseSlider(line, childAttributes);break;						case 'arrow':child = new UIArrow(this, childAttributes.x, childAttributes.y, childAttributes.colour, childAttributes.backgroundColours);break;						default:child = otherCommands(line, childAttributes);					}										if (child) {						if (child is MadSprite && line.@includeInLayout=="false")							MadSprite(child).includeInLayout=false;													_children[l] = child;						if (row) {							childAttributes.initPosition(child);						}						else {							childAttributes.position(child,_inGroup);						}												if (_style) {							var groupHeight:Number = ((mode=="rows") ? columnHeight : child.height) + _attributes.paddingV;						//	var top:Number = pos-_attributes.paddingV/2 + GROUP_OFFSET;							var doLines:Boolean = line.@lines.length()>0 && line.@lines[0].toString()!="false" && child is UIForm;							groupedBackground(l==0, l>=nColumns-1, pos-_attributes.paddingV/2 + GROUP_OFFSET, groupHeight, col, false, child as UIForm, doLines);						}												if (!childAttributes.visible)							child.visible = false;												if (included(child)) {						if (mode == "columns") {							pos += columnWidth + attributes.paddingH;						}						else if (mode == "rows") {							pos += columnHeight + attributes.paddingV;						}						else 							if (mode == "horizontal") {								pos = child.x + child.width + attributes.paddingH;							}							else if (mode != "frame") {								pos = child.y + child.height + attributes.paddingV;							}						}					}					col++;				}				_extra = 0;				if (row) {					layout(attributes);				} else if (_mode == "columns" && hasPicker) {					_pickerBackground = true;					pickerBackground(attributes);					_extra = UI.PADDING;				}				else if (!_inGroup && _mode.indexOf("scroll")<0 && !_style && attributes.backgroundColours.length>0) {					drawBackground();				}				return child;			}									override public function set visible(value:Boolean):void {				if (_lazyRender && value) {					parseBlock(_xml, _attributes, _localName, _row);					_lazyRender = false;					dispatchEvent(new Event(LOADED));				}				else if (_recycle && !value) {					UI.clear(this);					_lazyRender = true;					dispatchEvent(new Event(UNLOADED));				}				super.visible = value;			}			/** *  Rearrange the layout to new screen dimensions */				public function layout(attributes:Attributes):void {				_attributes = attributes.copy(_xml);								// _attributes.parse(_xml);								if (_lazyRender)					return;				if (_style || !_attributes.hasBorder && _xml.@border.length()>0 && _xml.@border[0]=="true") {					_attributes.y = UI.PADDING + _attributes.paddingV/2;					_attributes.x += UI.PADDING;					_attributes.width -= 2*UI.PADDING;					_attributes.height -= 2*UI.PADDING + _attributes.paddingV;				}				if (_xml.@width.length()>0)					_attributes.width = _xml.@width[0];				if (_xml.@height.length()>0)					_attributes.height = _xml.@height[0];								if (_row) {					_attributes.height = height;				}				_positions = [];				var xmlList:XMLList = xml.children();				var pos:Number = ((_mode=="vertical" || _mode=="rows" || _mode.indexOf("Panel")>=0 || _mode.indexOf("scroll")>=0) ? _attributes.y : _attributes.x);				var nColumns:int = numberOfColumns(xmlList);				var columnWidth:Number = (_attributes.width - (nColumns - 1) * _attributes.paddingH) / nColumns;				var columnHeight:Number = (_attributes.height - (nColumns - 1) * _attributes.paddingV) / nColumns;				var hasPicker:Boolean = false;				var col:int = 0;				var group:Boolean = false;								if (_style)					_style.graphics.clear();								for (var l:int=0;l<xmlList.length();l++) {					var line:XML=xmlList[l];					var localName:String = line.localName();					if (line.nodeKind() == "text" || localName=="data" || localName=="model" || localName=="sendModel")						continue;										var childAttributes:Attributes = _attributes.copy(line, true);					childAttributes.y = 0;					var child:DisplayObject = _children[l];										if (_mode=="columns") {						if (customWidths()) {							childAttributes.width = columnWidth = _widths[col];							childAttributes.x = pos;						}						else {							childAttributes.width = columnWidth;							childAttributes.x = pos;						}					}					else if (_mode=="rows") {							if (customHeights()) {								childAttributes.height = columnHeight = _heights[col];								childAttributes.y = pos;														}							else {								childAttributes.height = columnHeight;								childAttributes.y = pos;							}					}					else if (_mode=="horizontal") {						childAttributes.width += (childAttributes.x-pos);						if (childAttributes.width < 0)							childAttributes.width = 0;						childAttributes.x = pos;					}					else if (_mode != "frame") {						childAttributes.height += (childAttributes.y-pos);						if (childAttributes.height < 0)							childAttributes.height = 0;						childAttributes.y = pos;					}					if (UI.isContainer(localName)) {						if (child is IContainerUI) {							IContainerUI(child).layout(childAttributes);							child.x = childAttributes.x;							child.y = childAttributes.y;						}					}					else switch(localName) {						case 'group':						case 'clickableGroup': group = true;						case 'frame':						case 'horizontal':						case 'vertical':						case 'columns':						case 'rows': var newAttributes:Attributes = childAttributes.copy();	///////modified		//	if (localName=="rows" || localName=="columns")	///////				//		newAttributes.hasBorder = false;							newAttributes.x=0;							newAttributes.y=0;							UI.FormClass(child).layout(newAttributes);							break;						case 'picker': hasPicker = true;							IContainerUI(child).layout(childAttributes);break;							break;													case 'label':						//	if (_xml.@height.length()>0 && child is UILabel) 						//		UILabel(child).fixheight = Number(_xml.@height[0]);						//	if (childAttributes.fillH || _xml.@height.length()>0) {						//		UILabel(child).fixwidth = childAttributes.widthH;						//	}							if (line.@height.length()>0 && child is UILabel) 								UILabel(child).fixheight = Number(line.@height[0]);							if (childAttributes.fillH || line.@height.length()>0) {								UILabel(child).fixwidth = childAttributes.widthH;							}							if (line.@autosize.length() > 0 && line.@autosize != "false") {								UILabel(child).autoSize = TextFieldAutoSize.LEFT;							}							break;						case 'button':							if (childAttributes.fillV) {								UIButton(child).skinHeight = childAttributes.heightV;							}							if (childAttributes.fillH) {								UIButton(child).fixwidth = childAttributes.widthH;							}							break;						case 'input':						case 'slider': 							if (childAttributes.fillH) {								Object(child).fixwidth = childAttributes.widthH;							}							break;						case 'search':							UISearch(child).fixwidth = childAttributes.width;							break;												case 'arrow':						case 'switch': break;												case 'image':						case 'imageLoader': UIImage(child).attributesWidth = childAttributes.widthH;											UIImage(child).attributesHeight = childAttributes.heightV;							break;						default:							if (childAttributes.fillH) {								Object(child).width = childAttributes.widthH;							}												}					childAttributes.position(child, _inGroup && !_row);					_positions.push(child.x);										if (_style) {						var groupHeight:Number = ((_mode=="rows") ? columnHeight : child.height) + _attributes.paddingV;						var top:Number = pos-_attributes.paddingV/2 + GROUP_OFFSET;						var doLines:Boolean = line.@lines.length()>0 && line.@lines[0].toString()!="false" && child is UIForm;						groupedBackground(l==0, l>=nColumns-1, top, groupHeight, col, false, child as UIForm, doLines);					}										if (included(child)) {					if (_mode == "columns") {						pos += columnWidth + _attributes.paddingH;					}					else if (_mode == "rows") {						pos += columnHeight + _attributes.paddingV;					}					else  if (_mode == "horizontal") {							pos = child.x + child.width + _attributes.paddingH;						}						else if (_mode != "frame"){							pos = child.y + child.height + _attributes.paddingV;						}					}					col++;				}				_extra = 0;				if (_mode == "columns" && hasPicker) {					_pickerBackground = true;					pickerBackground(_attributes);					_extra = UI.PADDING;				}				else if (!_inGroup && !group && _mode.indexOf("scroll")<0 && !_style && !_row && _attributes.backgroundColours.length>0) {					drawBackground();				}			}									public function get hasPickerBackground():Boolean {				return _pickerBackground;			}									public function get children():Array {				return _children;			}									protected function included(child:DisplayObject):Boolean {				return !(child is MadSprite) || MadSprite(child).includeInLayout;			}			/** *  x positions of child UI components */			public function get positions():Array {				return _positions;			}			/** *  Re-render */			public function doLayout():void {				layout(_attributes);			}			protected function doLayoutHandler(event:Event):void {				layout(_attributes);				event.stopPropagation();			}			/** *  Number of children */			protected function numberOfColumns(xmlList:XMLList):int {				var result:int = 0;				for each (var column:XML in xmlList)  if (column.nodeKind() != "text") {					var localName:String = column.localName().toString();					if (localName!="data" && localName!="model" && localName!="sendModel")						result++;				}				return result;			}			/** *  Background chrome if this form contains picker components */			protected function pickerBackground(attributes:Attributes):void {				var colour:uint = attributes.backgroundColours.length>0 ? attributes.backgroundColours[0] : 0x666666;				graphics.clear();				graphics.beginFill(attributes.backgroundColours.length>1 ? attributes.backgroundColours[1] : colour);				var width:Number = attributes.width+2*_padding;				var height:Number = this.height+2*_padding;				graphics.drawRect(-_padding,-_padding,width,height); 				cutOuts(0.0);				var matr:Matrix=new Matrix();				var gradient:Array = [Colour.darken(colour,128),Colour.lighten(colour),Colour.darken(colour)];				matr.createGradientBox(width, this.height, Math.PI/2, 0, 0);				graphics.beginGradientFill(GradientType.LINEAR, gradient, [1.0,1.0,1.0], [0x00,0x66,0xff], matr);				graphics.drawRect(-_padding+1,-_padding+1,width-2,(height-2)/2);				cutOuts(-1.0);				graphics.beginFill(attributes.backgroundColours.length>2 ? attributes.backgroundColours[2] : Colour.darken(colour,-16));				graphics.drawRect(-_padding+1,-_padding+(height-2)/2,width-2,(height-2)/2);				cutOuts(1.0);				graphics.endFill();			}									protected function cutOuts(partial:int):void {				for (var i:int = 0; i< numChildren; i++) {					var child:DisplayObject = getChildAt(i);					if (child is UIPicker) {						UIPicker(child).drawShape(graphics, child.x, child.y, partial);					}				} 			}			/** *  Background chrome if this is a group or clickableGroup */			protected function groupedBackground(begin:Boolean,end:Boolean, top:Number, height:Number, count:int, click:Boolean=false, child:UIForm = null, lines:Boolean = false):void {				if (_groups) {					_groups[count] = {begin:begin, end:end, top:top, height:height, child:child, lines:lines};				}				var left:Number = (_mode.indexOf("scroll")>=0) ? UI.PADDING : 0;				_style.graphics.beginFill(_attributes.colour);				if (begin && end) {					_style.graphics.drawRoundRect(left, top, _attributes.width+2*UI.PADDING, height, 1.5 * CURVE);					}				else if (begin) {					UIGroupedList.curvedTop(_style.graphics,left, top, left+_attributes.width+2*UI.PADDING, top+height);				}				else if (end) {					UIGroupedList.curvedBottom(_style.graphics,left, top, left+_attributes.width+2*UI.PADDING, top+height+1);				}				else {					_style.graphics.drawRect(left, top, _attributes.width+2*UI.PADDING, height);				}								var colours:Vector.<uint> = child ? child.attributes.backgroundColours : null;				if (click) {					_style.graphics.beginFill(UIList.HIGHLIGHT);				}				else if (colours && colours.length>1) {					var matr:Matrix=new Matrix();					matr.createGradientBox(colours.length>2 ? colours[2] : width, colours.length>2 ? colours[2] : height+2*UI.PADDING, colours.length>3 ? colours[3]*Math.PI/180 : Math.PI/2, 0, top-UI.PADDING);					_style.graphics.beginGradientFill(GradientType.LINEAR, [colours[0],colours[1]], [1.0,1.0], [0x00,0xff], matr, SpreadMethod.REPEAT);				}				else if (colours && colours.length>0) {					_style.graphics.beginFill(colours[0]);				}				else if (_attributes.backgroundColours.length>0) {					_style.graphics.beginFill(_attributes.backgroundColours[count % _attributes.backgroundColours.length]);				}				else {					_style.graphics.beginFill(CELL_COLOUR);				}				if (begin && end) {					_style.graphics.drawRoundRect(left+1, top+1, _attributes.width+2*UI.PADDING-2, height-2, 1.5 * CURVE);					}				else if (begin) {					UIGroupedList.curvedTop(_style.graphics,left+1, top+1, left+_attributes.width+2*UI.PADDING-1, top+height);				}				else if (end) {					UIGroupedList.curvedBottom(_style.graphics,left+1, top+1, left+_attributes.width+2*UI.PADDING-1, top+height);					_style.graphics.endFill();					_style.graphics.drawRect(0,top+height+_attributes.paddingV/2,1,1);				}				else {					_style.graphics.drawRect(left+1, top+1, _attributes.width+2*UI.PADDING-2, height-1);				}				if (child && lines) {					drawLines(UIForm(child), top, height);				}			}			/** *  Group vertical dividing lines */			protected function drawLines(child:UIForm, top:Number, height:Number):void {				_style.graphics.beginFill(_attributes.colour);				var positions:Array = child.positions;				for (var i:int = 1; i<positions.length; i++) {					_style.graphics.drawRect(child.x+positions[i] - _attributes.paddingH/2, top+1, 1, height);				}			}			/** *  Group clicked handler */			protected function groupClicked(event:MouseEvent):void {								if (event.target == this) {					return;				}				if ((!_insideScroller && event.target is UIForm) || event.target == _style || (event.target is MadSprite && !MadSprite(event.target).clickable)) {					stage.addEventListener(MouseEvent.MOUSE_UP, resetGroupClicked);					if (_style.hitTestPoint(stage.mouseX, stage.mouseY, true)) {						for (var i:int = _groups.length-1; i>=0; i--) {							var item:Object = _groups[i];							if (mouseY>item.top) {								if (_disable.indexOf(i)>=0)									return;								_index = i;								groupedBackground(i==0,i==_groups.length-1,item.top, item.height, i, true, item.child, item.lines);								break;							}						}						dispatchEvent(new Event(CLICKED));					}				}			}			/** *  Clear group clicked highlight */			protected function resetGroupClicked(event:MouseEvent):void {				stage.removeEventListener(MouseEvent.MOUSE_UP, resetGroupClicked);				if (_index>=0 && _index<_groups.length) {					var item:Object = _groups[_index];					groupedBackground(_index==0, _index==_groups.length-1, item.top, item.height, _index, false, item.child);					dispatchEvent(new Event(CLICKED_END));				}			}			/** *  Index of last row clicked */			public function get index():int {				return _index;			}									public function drawComponent():void {					drawBackground();			}			/** *  Draw background */			public function drawBackground(colours:Vector.<uint> = null):void {				if (!colours) {					colours = _attributes.backgroundColours;				}							//	UI.drawBackgroundColour(colours,_attributes.width,_attributes.height+(_attributes.hasBorder ? UI.PADDING : 0)+4,this, _attributes.hasBorder ? UI.PADDING : 0);				if (_attributes.x==0) {					UI.drawBackgroundColour(colours, _attributes.x + _attributes.width, _attributes.y + _attributes.height + TWEAK, this, (_attributes.hasBorder ? UI.PADDING : 0));				}				else {					var padding:Number = (_attributes.hasBorder ? 2*UI.PADDING : 0);					UI.drawBackgroundColour(colours, padding + _attributes.width, padding + _attributes.height + TWEAK, this, 0); //(_attributes.hasBorder ? UI.PADDING : 0));				}				}			/** *  Interpret non-MadComponents for XML tags with external mamespaces */			protected function otherCommands(xml:XML, attributes:Attributes):DisplayObject {					var className:String = xml.localName();				if (!className)					return null;				var nameSpace:String = (className!=null) ? xml.name().uri : "";				className = nameSpace+"::"+className;				var ChildClass:Class = getDefinitionByName(className) as Class;				if (ChildClass) {					var child:* = new ChildClass();					addChild(child);					for each (var attribute:XML in xml.attributes()) {						var name:String = attribute.name();						var value:String = xml.attribute(name)[0];						if (child.hasOwnProperty(name)) {							try {								child[name] = value;							} catch(e:Error) {								child[name] = getDefinitionByName(value) as Class;							}						}					}					if (attributes.fillH) {						child.width = attributes.widthH;					}					return child;				}				else {					return null;				}			}			/** *  Create a UILabel */			protected function parseLabel(xml:XML, attributes:Attributes):DisplayObject {				var label:UILabel=new UILabel(this, attributes.x, attributes.y, xml.toString());				assignToLabel(xml, label);				if (xml.@height.length()>0)					label.fixheight = Number(xml.@height[0]);				if (attributes.fillH || xml.@height.length()>0) {					label.fixwidth = attributes.widthH;					var textAlign:String = attributes.textAlign;					if (textAlign != "") {						var format:TextFormat = new TextFormat();						format.align = textAlign;						label.defaultTextFormat = format;					}				}				if (xml.@autosize.length() > 0 && xml.@autosize != "false")					label.autoSize = TextFieldAutoSize.LEFT;				return label;			}			/** *  Assign text to a label */			protected function assignToLabel(xml:XML, label:UILabel):Boolean {				if (xml.hasComplexContent()) {					var xmlString:String = xml.toXMLString();					var htmlText:String = xmlString.substring(xmlString.indexOf(">")+1,xmlString.lastIndexOf("<"));										label.htmlText = htmlText;					if (label.text=="") {						label.text=" ";					}					return true;				}				return false;			}			/** *  Create a UIButton */			protected function parseButton(xml:XML, attributes:Attributes):DisplayObject {				var colourButton:UIButton = new UIButton(this, attributes.x, attributes.y, xml.toString(), attributes.colour, attributes.backgroundColours, xml.@alt == "true");					if (xml.@skin.length()>0) {					colourButton.skin = xml.@skin[0];				}								if (attributes.fillH) {					colourButton.fixwidth = attributes.widthH;				}				if (attributes.fillV) {					colourButton.skinHeight = attributes.heightV;				}								if (xml.@curve.length()>0) {					colourButton.curve = parseFloat(xml.@curve);				}												return colourButton;			}			/** *  Create a UIInput */			protected function parseInput(xml:XML, attributes:Attributes):DisplayObject {				var inputText:UIInput = new UIInput(this, attributes.x, attributes.y, xml.toString(), attributes.backgroundColours, xml.@alt.length()>0, xml.@prompt.length()>0 ? xml.@prompt[0].toString() : "", xml.@promptColour.length()>0 ? UI.toColourValue(xml.@promptColour[0].toString()) : UIBlueText.GREY);				if (attributes.fillH) {					inputText.fixwidth = attributes.widthH;				}				UIBlueText(inputText.inputField).password = xml.@password.length()>0 && xml.@password == "true";				return inputText;			}			/** *  Create a UISwitch */			protected function parseSwitch(xml:XML, attributes:Attributes):DisplayObject {				var switchButton:UISwitch;				var labels:Array = xml.toString().split(",");				if (labels.length>1)						switchButton = new UISwitch(this, attributes.x, attributes.y, attributes.colour, labels[0], labels[1], attributes.backgroundColours,xml.@alt=="true");					else						switchButton = new UISwitch(this, attributes.x, attributes.y, attributes.colour, "ON", "OFF", attributes.backgroundColours,xml.@alt=="true");				if (xml.@state=="true")					switchButton.state = true;				return switchButton;			}			/** *  Create a UISlider */			protected function parseSlider(xml:XML, attributes:Attributes):DisplayObject {				var slider:UISlider = new UISlider(this, attributes.x, attributes.y, attributes.backgroundColours, xml.@alt=="true");				if (attributes.fillH) {					slider.fixwidth = attributes.widthH;				}				if (xml.@value.length()>0) {					slider.value = Number(xml.@value);				}				return slider;			}			/** *  Remove all child components */			public function clear():void {				UI.clear(this);			}			/** *  Search for component by id */			public function findViewById(id:String, row:int = -1, group:int = -1):DisplayObject {				var found:DisplayObject = null;				for (var i:int = 0; i < numChildren && !found; i++) {					var item:DisplayObject = getChildAt(i);					if (item.name == id)						found = item;					if (!found && (item is IContainerUI)) {						found = IContainerUI(item).findViewById(id, row, group);					}				}				return found;			}			/** *  Form height */			override public function get height():Number {				if (_height>0) return _height;				var result:Number = 0;				for (var i:int = 0; i<numChildren; i++) {					var child:DisplayObject = DisplayObject(getChildAt(i));					if (included(child)) {						var childHeight:Number = child.y + child.height;						if (childHeight > result)							result = childHeight;					}				}				return result + _extra;			}			/** *  Form width */			override public function get width():Number {				var result:Number = 0;				for (var i:int = 0; i<numChildren; i++) {					var child:DisplayObject = DisplayObject(getChildAt(i));					var childWidth:Number = child.x + child.width;					if (childWidth > result)						result = childWidth;				}				return result;			}			/** *  Assign to child components by passing an array of objects */			public function set data(values:Object):void {				for (var idName:String in values) {					var uiThing:* = findViewById(idName);					if (uiThing) {						try {							uiThing.text = XML(values[idName]).toString();						}						catch(error:Error) {							uiThing.text = values[idName];						}					}				}				if (_autoLayout)					layout(_attributes);			}			/** *  Model */			public function get model():Model {				return _model;			}			/** *  For a UIForm, pages returns [this] */			public function get pages():Array {				return [this];			}									public function destructor():void {				removeEventListener(UIImageLoader.LOADED, doLayoutHandler);				removeEventListener(MouseEvent.MOUSE_DOWN, groupClicked);				stage.removeEventListener(MouseEvent.MOUSE_UP, resetGroupClicked);				UI.clear(this);			}		}	}