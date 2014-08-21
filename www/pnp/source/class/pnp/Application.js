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
	
		this.__camup = new qx.ui.basic.Image("http://192.168.1.19:8090/?action=stream");
		this.__camdown = new qx.ui.basic.Image("http://192.168.1.19:8091/?action=stream");
		this.__camvanity = new qx.ui.basic.Image("http://192.168.1.19:8092/?action=stream");

		this.__cambox.add(this.__camup);
		this.__cambox.add(this.__camdown);
		this.__cambox.add(this.__camvanity);

/*
		##	 		X	Y	Z	A

		Nozzle Requested
		Nozzle Coordinates

		Camera Requested
		Camera Coordinates

		GCode Mode:		


		var tm1 = new qx.ui.table.model.Simple();
		tm1.setColumns(["","X", "Y", "Z", "A"]);
		tm1.setData(	[
				["", 0, 0, 68, 0],
				["", 0, 0, 68, 0]
				]);

		var table = new qx.ui.table.Table(tm1);


		var gridlayout = new qx.ui.layout.Grid();
		var statusgrid = new qx.ui.container.Composite(gridlayout);

		statusgrid.add(new qx.ui.basic.Label("X"), {row: 0, column: 1});
		statusgrid.add(new qx.ui.basic.Label("Y"), {row: 0, column: 2});
		statusgrid.add(new qx.ui.basic.Label("Z"), {row: 0, column: 3});
		statusgrid.add(new qx.ui.basic.Label("A"), {row: 0, column: 4});

		statusgrid.add(new qx.ui.basic.Label("Nozzle Requested:"), {row: 2, column: 0});
		statusgrid.add(new qx.ui.basic.Label("Nozzle Coordinates:"), {row: 3, column: 0});

		statusgrid.add(new qx.ui.basic.Label("Camera Requested:"), {row: 5, column: 0});
		statusgrid.add(new qx.ui.basic.Label("Camera Coordinates:"), {row: 6, column: 0});

		statusgrid.add(new qx.ui.basic.Label("GCode Mode:"), {row: 8, column: 0});






		this.__cambox.add(table);

*/


	},

	__setUpStatus : function() {
		var vbox = new qx.ui.layout.VBox();
		this.__statusBox = new qx.ui.container.Composite(vbox);

		var tm1 = new qx.ui.table.model.Simple();
		tm1.setColumns(["","X", "Y", "Z", "A"]);
		tm1.setData([
				["Nozzle Requested", 0, 0, 68, 0],
				["Nozzle Actual", 0, 0, 68, 0]
		]);

		var t1 = new qx.ui.table.Table(tm1);
		t1.set({ height: 200 });
		t1.setAllowShrinkX(true);
		t1.setAllowShrinkY(true);


		var tm2 = new qx.ui.table.model.Simple();
		tm2.setColumns(["","X", "Y", "Z", "A"]);
		tm2.setData([
				["Nozzle Requested", 0, 0, 68, 0],
				["Nozzle Actual", 0, 0, 68, 0]
		]);

		var t2 = new qx.ui.table.Table(tm1);
		t2.setAllowShrinkX(true);
		t2.setAllowShrinkY(true);

		this.__statusBox.add(t1)
		this.__statusBox.add(t2)
		
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

		var send = new qx.ui.form.Button("Get Echo");
		send.addListener("execute", function(e) {
			var rpc = new qx.io.remote.Rpc();
			rpc.set({ url : 'jsonrpc/',
				  serviceName : 'rpc'});
			rpc.callAsync(function(ret, exc) {
				if (exc) {
					alert("Error " + exc.code + " : " + exc.message);
				} else {
					alert("World of awesome: " + ret);
				}
			},'echo', 42);
		});


	
		this.__mainvbox0.add(send);
		doc.add(this.__mainvbox0);


	}
  }
});
