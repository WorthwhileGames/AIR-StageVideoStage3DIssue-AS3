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

	// Make sure to test on a device to reproduce the issue:
	//   Stage2D turns opaque/black when NetStream is disposed
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
			
			stage3D = stage.stage3Ds[0];
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			stage3D.requestContext3D(Context3DRenderMode.AUTO);
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
			
			// Setup NetStream
			nc = new NetConnection();
			nc.connect(null);
			ns =  new NetStream(nc);
			
			setupStageVideo();
		}
		
		private function onMouseUp(ev:Event): void
		{
			if (stage3D.visible)
			{
				stage3D.visible = false;
				var url:String = File.applicationDirectory.resolvePath("WwVideoClip_960x720.mp4").url;
				ns.play(url);
			}
			else
			{
				stage3D.visible = true;
				// On devices, Stage2D turns opaque/black when NetStream is disposed (2nd click)
				ns.dispose();
			}
		}
		
		private function onEnterFrame(ev:Event): void
		{
			// Render the scene
			context3D.clear(0.5, 0.5, 0.5);
			sprite.render();
			context3D.present();
		}
		
		// Video
		
		private function setupStageVideo():void
		{
			ns.bufferTime = 2;
			ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			
			nsClientObject = new Object();
			ns.client = nsClientObject;
			nsClientObject.onMetaData = onNSMetaData;
			nsClientObject.onCuePoint = onNSCuePoint;
			
			if(stageVideoAvailable){
				stageVideo = stage.stageVideos[0];
				stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, onStageVideoRenderState);
				stageVideo.attachNetStream(ns);
			}
			
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