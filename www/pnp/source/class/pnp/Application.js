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

	__rpc_xyza	: null,

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

	__setUpCameras : function() {
		var hbox0 = new qx.ui.layout.HBox();
		hbox0.setSpacing(4);
	
		this.__cambox = new qx.ui.container.Composite(hbox0);
	
		this.__camup = new qx.ui.embed.Iframe("c1.html");
		this.__camup.set({ scrollbar: "no", width: 320, height: 240});

		this.__camdown = new qx.ui.embed.Iframe("c2.html");
		this.__camdown.set({ scrollbar: "no", width: 320, height: 240});

		this.__camvanity = new qx.ui.embed.Iframe("c3.html");
		this.__camvanity.set({ scrollbar: "no", width: 320, height: 240});

		this.__cambox.add(this.__camup);
		this.__cambox.add(this.__camdown);
		this.__cambox.add(this.__camvanity);


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


	},

	__setUpGUI : function() {
		var doc = this.getRoot();
		var vbox0 = new qx.ui.layout.VBox();
		vbox0.setSpacing(4);
	
		this.__mainvbox0 = new qx.ui.container.Composite(vbox0);

		this.__setUpCameras();
		this.__setUpStatus();
		this.__mainvbox0.add(this.__cambox);

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


		this.__rpc_xyza.callAsync(handler, "echo", "xyza");
		doc.add(this.__mainvbox0);


	}
  }
});
