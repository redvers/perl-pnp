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

	// Camera images for moving around
	__cambox	: null,
	__camup		: null,
	__camdown	: null,
	__camvanity	: null,

	__statusBox	: null,

	__tm1		: null,
	__tm2		: null,
	__tm3		: null,

	__rpc_xyza	: null,
	__rpc_relxyza	: null,
	__rpc_feeder	: null,

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

	crosshair : function(context) {
		context.beginPath();
		context.moveTo(0, 120);
		context.lineTo(320, 120);
		context.moveTo(160, 0);
		context.lineTo(160, 240);
		context.strokeStyle = "#FF0000";
		context.stroke();

	},

	__setUpCameras : function() {
		var hbox0 = new qx.ui.layout.HBox();
		hbox0.setSpacing(4);
		var img = new Image;
		var that = this;
		img.src = "http://192.168.1.19:8092/?action=stream";
	
		var imgdown = new Image;
		imgdown.src = "http://192.168.1.19:8091/?action=stream";

		var imgvanity = new Image;
		imgvanity.src = "http://192.168.1.19:8090/?action=stream";

		this.__cambox = new qx.ui.container.Composite(hbox0);

		this.__camup = new qx.ui.embed.Canvas();
		this.__camup.set({ canvasWidth: 320, canvasHeight: 240, width: 320 });
		var ctx = this.__camup.getContext2d();

		this.__rpc_relxyza = new qx.io.remote.Rpc(
			"http://localhost:3000/jsonrpc/",
			"rpc"
		);

		var that = this;
		var handler = function(result, exc) {
			if (exc == null) {
			} else {
			}
		};

		this.__camup.addListener("click", function(e) {
				var x = e.getViewportLeft();
				var y = e.getViewportTop();

				x -= (320 * 2 ) + 8;	// Now we're
				y -= 4;			// in the correct frame

				x -= (320 / 2);		// Relative 
				y -= (240 / 2);		// to crosshairs

				x /= 50;
				y /= 50;


				// x and y change due to camera mounting
				this.__rpc_relxyza.callAsync(handler, "relmove", [y,x]);
		}, that, false);

		this.__camdown = new qx.ui.embed.Canvas();
		this.__camdown.set({ canvasWidth: 320, canvasHeight: 240, width: 320 });
		var ctxdown = this.__camdown.getContext2d();

		this.__camvanity = new qx.ui.embed.Canvas();
		this.__camvanity.set({ canvasWidth: 320, canvasHeight: 240, width: 320 });
		var ctxvanity = this.__camvanity.getContext2d();

		this.__cambox.add(this.__camvanity);
		this.__cambox.add(this.__camdown);
		this.__cambox.add(this.__camup);

		var timer = qx.util.TimerManager.getInstance();

		timer.start(function(nowt, timerId) {
			ctx.drawImage(img,0,0);
			this.crosshair(ctx);

			ctxdown.drawImage(imgdown,0,0);
			this.crosshair(ctxdown);

			ctxvanity.drawImage(imgvanity,0,0);
			this.crosshair(ctxvanity);
		},
		200, this, null, 3000);
	},

	__setUpStatus : function() {
		var vbox = new qx.ui.layout.VBox();
		vbox.setSpacing(4);
		this.__statusBox = new qx.ui.container.Composite(vbox);

		this.__tm1 = new qx.ui.table.model.Simple();
		this.__tm1.setColumns(["Camera Coordinates","X", "Y", "Z", "A"]);
		this.__tm1.setData([
				["Requested", 0, 0, 68, 0],
				["Actual", 0, 0, 68, 0]
		]);

		var custom = { tableColumnModel : function(obj) { return new qx.ui.table.columnmodel.Resize(obj); } };
		var t1 = new qx.ui.table.Table(this.__tm1, custom);
		var tcm = t1.getTableColumnModel();
		var resizeBehavior = tcm.getBehavior();
		resizeBehavior.setWidth(0, "60%");
		resizeBehavior.setWidth(1, "10%");
		resizeBehavior.setWidth(2, "10%");
		resizeBehavior.setWidth(3, "10%");
		t1.set({ height: 120, width: 465 });

		this.__tm2 = new qx.ui.table.model.Simple();
		this.__tm2.setColumns(["Nozzle Coordinates","X", "Y", "Z", "A"]);
		this.__tm2.setData([
				["Requested", 0, 0, 68, 0],
				["Actual", 0, 0, 68, 0]
		]);

		var t2 = new qx.ui.table.Table(this.__tm2, custom);
		var tcm = t2.getTableColumnModel();
		var resizeBehavior = tcm.getBehavior();
		resizeBehavior.setWidth(0, "60%");
		resizeBehavior.setWidth(1, "10%");
		resizeBehavior.setWidth(2, "10%");
		resizeBehavior.setWidth(3, "10%");
		t2.set({ height: 120, width: 465 });
		t2.setAllowShrinkX(true);
		t2.setAllowShrinkY(true);

		this.__statusBox.add(t1);
		this.__statusBox.add(t2);
		this.__cambox.add(this.__statusBox);

		this.__rpc_xyza = new qx.io.remote.Rpc(
			"http://localhost:3000/jsonrpc/",
			"rpc"
		);

		var that = this;
		var handler = function(result, exc) {
			if (exc == null) {
				that.__tm1.setValue(1, 1, result[0][0]);
				that.__tm1.setValue(2, 1, result[0][1]);
				that.__tm1.setValue(3, 1, result[0][2]);
				that.__tm1.setValue(4, 1, result[0][3]);

				that.__tm2.setValue(1, 1, result[1][0]);
				that.__tm2.setValue(2, 1, result[1][1]);
				that.__tm2.setValue(3, 1, result[1][2]);
				that.__tm2.setValue(4, 1, result[1][3]);
			} else {
				alert("Exception during async call: " + exc);
			}
		};


		this.__rpc_xyza.callAsync(handler, "xyza", "xyza");

	},

	__setUpFeeders : function() {
		var hbox = new qx.ui.layout.HBox();
		this.__feederbox = new qx.ui.container.Composite(hbox);
		hbox.setSpacing(4);

		this.__tm3 = new qx.ui.table.model.Simple();
		this.__tm3.setColumns(["ID", "Package", "Value", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" ]);

		var custom = { tableColumnModel : function(obj) { return new qx.ui.table.columnmodel.Resize(obj); } };
                var t3 = new qx.ui.table.Table(this.__tm3, custom);
		t3.set({ width: 968 });
                var tcm = t3.getTableColumnModel();
                var resizeBehavior = tcm.getBehavior();
                resizeBehavior.setWidth(0, "3%");
                resizeBehavior.setWidth(1, "8%");
                resizeBehavior.setWidth(2, "8%");

		this.__feederbox.add(t3);

		this.__rpc_feeder = new qx.io.remote.Rpc(
			"http://localhost:3000/jsonrpc/",
			"rpc"
		);

		var that = this;
		var handler = function(result, exc) {
			if (exc == null) {
				that.__tm3.setData(result);
//				that.__tm3.setValue(2, 1, result[0][1]);
//				that.__tm3.setValue(3, 1, result[0][2]);
//				that.__tm3.setValue(4, 1, result[0][3]);
			} else {
				alert("Exception during async call: " + exc);
			}
		};


		this.__rpc_feeder.callAsync(handler, "feeder", "feeder");
	},

	__setUpGUI : function() {
		var doc = this.getRoot();
		var vbox0 = new qx.ui.layout.VBox();
		vbox0.setSpacing(4);
	
		this.__mainvbox0 = new qx.ui.container.Composite(vbox0);

		this.__setUpCameras();
		this.__setUpStatus();
		this.__setUpFeeders();
		this.__mainvbox0.add(this.__cambox);
		this.__mainvbox0.add(this.__feederbox);

		doc.add(this.__mainvbox0);


	}
  }
});
