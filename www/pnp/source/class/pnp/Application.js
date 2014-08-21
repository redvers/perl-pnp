/* ************************************************************************

   Copyright:

   License:

   Authors:

************************************************************************ */

/**
 * This is the main application class of your custom application "pnp"
 *
 * @asset(pnp/*)
 */
qx.Class.define("pnp.Application",
{
  extend : qx.application.Standalone,

  /*
  *****************************************************************************
     MEMBERS
  *****************************************************************************
  */

  members :
  {

	// private members
	__mainvbox0	: null,
	__canvasUp	: null,

	// Camera images for moving around
	__cambox	: null,
	__camup		: null,
	__camdown	: null,
	__camvanity	: null,

    /**
     * This method contains the initial application code and gets called 
     * during startup of the application
     * 
     * @lint ignoreDeprecated(alert)
     */

	main : function() {
		this.base(arguments);

		if (qx.core.Environment.get("qx.debug")) {
			qx.log.appender.Native;
			qx.log.appender.Console;
		}

		this.__setUpGUI();


	},

	__callcamup : function() {
		this.__canvasUp = new qx.ui.embed.Canvas().set(
			{
				canvasWidth: 800,
				canvasHeight: 600,
				syncDimension: true
			});

		this.__canvasUp.set({
			width:	800,
			height:	600});
		
		this.__canvasUp.addListener("redraw", function(e) {
			var data = e.getData();
//			var width = data.width;
//			var height = data.height;
			var ctx = data.context;

			var camUpImage = new Image();
//			camUpImage.src = "http://192.168.1.19:8090/?action=stream";
			camUpImage.src = "https://www.google.com/images/srpr/logo11w.png";

			ctx.drawImage(camUpImage, 0, 0,800,600);

//			ctx.fillStyle = "rgb(200,0,0)";
//			ctx.fillRect(640,480,width-5, height-5);
			
			}, this);


	},

	__setUpCameras : function() {
		var hbox0 = new qx.ui.layout.HBox();
		hbox0.setSpacing(4);
	
		this.__cambox = new qx.ui.container.Composite(hbox0);
	
		this.__callcamup();
		this.__camup = new qx.ui.basic.Image("http://192.168.1.19:8090/?action=stream");
		this.__camdown = new qx.ui.basic.Image("http://192.168.1.19:8091/?action=stream");
		this.__camvanity = new qx.ui.basic.Image("http://192.168.1.19:8092/?action=stream");
	
//		this.__cambox.add(this.__canvasUp);
		this.__cambox.add(this.__camup);
		this.__cambox.add(this.__camdown);
		this.__cambox.add(this.__camvanity);

	},

	__setUpGUI : function() {
		var doc = this.getRoot();
		var vbox0 = new qx.ui.layout.VBox();
		vbox0.setSpacing(4);
	
		this.__mainvbox0 = new qx.ui.container.Composite(vbox0);

		this.__setUpCameras();

		this.__mainvbox0.add(this.__cambox);
	
		doc.add(this.__mainvbox0);


	}
  }
});
