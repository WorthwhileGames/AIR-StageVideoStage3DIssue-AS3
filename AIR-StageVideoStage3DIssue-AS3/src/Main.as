package
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.StageVideoEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.media.StageVideo;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	/**
	 *   A Tool to help troubleshoot an undesirable interaction between StageVideo and Stage3D 
	 *   @author Andrew Rapo, www.WorthwhileGames.org
	 *   https://github.com/WorthwhileGames/AIR-StageVideoStage3DIssue-AS3
	 *
	 * Make sure to test on a device to reproduce the issue:
	 *   Stage2D turns opaque/black when NetStream is attached or disposed
	 * Tap any blue circle to toggle Stage3D visibility on and off
	 *   The blue circles should overlay transparently on the Stage3D scene (AIR logo)
	 * Tap the green buttons from left to right to see the issue
	 * Button1: Instantiates the NetStream - so far, so good
	 * Button2: Attaches the NetStream to StageVideo - 2D stage goes opaque
	 * Button3: Makes Stage3D invisible and plays a video - 2D stage behaves normally again
	 * 	 Tap a blue circle to see normal 2D stage behavior
	 * Button4: Disposes the NetStream - 2D stage goes opaque
	 */
	public class Main extends Sprite
	{
		[Embed(source="Default-Landscape.png")]
		private static const TEXTURE:Class;
		
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		private var sprite:Stage3DSprite;
		
		private var nc:NetConnection;
		private var ns:NetStream;
		private var nsClientObject:Object;
		
		private var stageVideoAvailable:Boolean = true;
		private var stageVideo:StageVideo;
		
		private var button1:MovieClip;
		private var button2:MovieClip;
		private var button3:MovieClip;
		private var button4:MovieClip;
		
		public function Main()
		{
			super();
			
			// support autoOrients
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var mc:MovieClip;
			
			for (var i:int=0; i<8; i++)
			{
				for (var j:int=0; j<6; j++)
				{
					mc = new MovieClip();
					mc.graphics.beginFill(0x3064FF,0.5);
					mc.graphics.drawCircle(64 + (i * 128), 64 + (j * 128), 64);
					addChild(mc);
				}
			}
			
			button1 = new MovieClip();
			button1.graphics.beginFill(0x00ff9c,1.0);
			button1.graphics.drawRoundRect(10, 20, 200, 200, 6, 6);
			addChild(button1);
			button1.addEventListener(MouseEvent.MOUSE_UP, onSetupNetStream);
			
			button2 = new MovieClip();
			button2.graphics.beginFill(0x00ff9c,1.0);
			button2.graphics.drawRoundRect(220, 20, 200, 200, 6, 6);
			addChild(button2);
			button2.addEventListener(MouseEvent.MOUSE_UP, onAttachNetStream);
			
			button3 = new MovieClip();
			button3.graphics.beginFill(0x00ff9c,1.0);
			button3.graphics.drawRoundRect(430, 20, 200, 200, 6, 6);
			addChild(button3);
			button3.addEventListener(MouseEvent.MOUSE_UP, onPlayVideo);
			
			button4 = new MovieClip();
			button4.graphics.beginFill(0x00ff9c,1.0);
			button4.graphics.drawRoundRect(640, 20, 200, 200, 6, 6);
			addChild(button4);
			button4.addEventListener(MouseEvent.MOUSE_UP, onDisposeNetStream);
			
			stage3D = stage.stage3Ds[0];
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			stage3D.requestContext3D(Context3DRenderMode.AUTO);
		}
		
		private function onEnterFrame(ev:Event): void
		{
			// Render the scene
			context3D.clear(0.5, 0.5, 0.5);
			sprite.render();
			context3D.present();
		}
		
		protected function onContextCreated(ev:Event): void
		{
			// Setup context
			stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			context3D = stage3D.context3D;			
			context3D.configureBackBuffer(
				stage.stageWidth,
				stage.stageHeight,
				0,
				false
			);
			context3D.enableErrorChecking = true;
						
			sprite = new Stage3DSprite(context3D);
			sprite.bitmapData = (new TEXTURE()).bitmapData;
			
			// Start the simulation
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			
		}
		
		private function onMouseUp(ev:Event): void
		{
			if (stage3D)
			{
				if (stage3D.visible)
				{
					stage3D.visible = false;
				}
				else
				{
					stage3D.visible = true;
					
				}
			}
		}
		
		// Setting up Netstream does NOT cause the 2D stage to become opaque
		private function onSetupNetStream(ev:Event): void
		{
			button1.visible = false;
			stage3D.visible = true;
			ev.stopImmediatePropagation();
			
			nc = new NetConnection();
			nc.connect(null);
			ns =  new NetStream(nc);
			
			
			ns.bufferTime = 2;
			ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			
			nsClientObject = new Object();
			ns.client = nsClientObject;
			nsClientObject.onMetaData = onNSMetaData;
			nsClientObject.onCuePoint = onNSCuePoint;
		}
		
		// Attaching the NetStream to StageVideo DOES cause the 2D stage to become opaque
		private function onAttachNetStream(ev:Event): void
		{
			button2.visible = false;
			stage3D.visible = true;
			ev.stopImmediatePropagation();
			
			if(stageVideoAvailable){
				stageVideo = stage.stageVideos[0];
				stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, onStageVideoRenderState);
				stageVideo.attachNetStream(ns);
			}
		}
		
		// Playing a video causes the 2D stage to behave normally again - non-opaque
		private function onPlayVideo(ev:Event): void
		{
			button3.visible = false;
			ev.stopImmediatePropagation();
			stage3D.visible = false;
			var url:String = File.applicationDirectory.resolvePath("WwVideoClip_960x720.mp4").url;
			if (ns) ns.play(url);
		}
		
		// Disposing the NetStream DOES cause the 2D stage to become opaque
		private function onDisposeNetStream(ev:Event): void
		{
			button1.visible = true;
			button2.visible = true;
			button3.visible = true;
			stage3D.visible = true;
			ev.stopImmediatePropagation();
			// On devices, Stage2D turns opaque/black when NetStream is disposed (2nd click)
			if (ns) ns.dispose();
		}
		
		private function onStageVideoRenderState(e:StageVideoEvent):void{
			stageVideo.viewPort = new Rectangle( 32, 24, 960, 720);
		}
		
		private function onNSCuePoint(info:Object):void{
			
		}
		
		private function onNSMetaData(info:Object):void{
			
		}
		
		private function onNetStatus(e:NetStatusEvent):void
		{
			switch(e.info.code){
				case "NetStream.Play.StreamNotFound":
					break;
				case "NetStream.Play.Start":
					break;
				case "NetStream.Play.Stop":
					break;
				case "NetStream.Pause.Notify":
					break;
				case "NetStream.Unpause.Notify":
					break;
				case "NetStream.Buffer.Empty":
					break;
				case "NetStream.Buffer.Full":
					break;
				case "NetStream.Buffer.Flush":
					break;
			}
		}
	}
}