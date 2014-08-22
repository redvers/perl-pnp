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
		this.__statusBox = new qx.ui.container.Composite(vbox);

//		this.__tm1 = new pnp.RemoteDataModel();
//		this.__tm1.setColumns( [ "", "X", "Y", "Z", "A" ], ["none", "x", "y", "z", "a"] );
		var t1 = new qx.ui.table.Table();
//		t1.setTableModel(this.__tm1);



		t1.set({ height: 120 });
		t1.setAllowShrinkX(true);
		t1.setAllowShrinkY(true);


		var tm2 = new qx.ui.table.model.Simple();
		tm2.setColumns(["","X", "Y", "Z", "A"]);
		tm2.setData([
				["Camera Requested", 0, 0, 68, 0],
				["Camera Actual", 0, 0, 68, 0]
		]);

		var t2 = new qx.ui.table.Table(tm2);
		t2.set({ height: 120 });
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

/*
		var send = new qx.ui.form.Button("Get Echo");
		send.addListener("execute", function(e) {
			var rpc = new qx.io.remote.Rpc();
			rpc.set({ url : 'jsonrpc/',
				  serviceName : 'rpc'});
			rpc.callAsync(function(ret, exc) {
				if (exc) {
					alert("Error " + exc.code + " : " + exc.message);
				} else {
					var array = JSON.parse(ret);
					alert("World of awesome: " + array + [1,1,1,1]);
					alert("wtf");
					

				}
			},'echo', 42);
		});


	
		this.__mainvbox0.add(send);
*/		
		doc.add(this.__mainvbox0);


	}
  }
});
