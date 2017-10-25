ControlBusMeterView {

	classvar serverMeterViews, updateFreq = 10, dBLow = -80, meterWidth = 15, gapWidth = 4, <height = 230;
	classvar serverCleanupFuncs;

	var <view;
	var busresp, synthFunc, responderFunc, server, buses, names, busmeters, startResponderFunc;

	*new { |aserver, parent, leftUp, buses, names|
		^super.new.init(aserver, parent, leftUp, buses, names)
	}

	*getWidth { arg numBuses, server;
		^20+((numBuses + 2) * (meterWidth + gapWidth))
	}

	init { arg aserver, parent, leftUp, abuses, anames;
		var innerView, viewWidth, levelIndic, palette;

		server = aserver;

		buses = abuses;

		if (anames.size>=buses.size) {names = anames} {names = buses.collect(_.asString)};

		viewWidth= this.class.getWidth(buses.size);

		leftUp = leftUp ? (0@0);

		view = CompositeView(parent, Rect(leftUp.x, leftUp.y, viewWidth, height) );
		view.onClose_( { this.stop });
		innerView = CompositeView(view, Rect(10, 25, viewWidth, height) );
		innerView.addFlowLayout(0@0, gapWidth@gapWidth);

		// dB scale
		UserView(innerView, Rect(0, 0, meterWidth, 195)).drawFunc_( {
			try {
				Pen.color = \QPalette.asClass.new.windowText;
			} {
				Pen.color = Color.white;
			};
			Pen.font = Font.sansSerif(10).boldVariant;
			Pen.stringCenteredIn("0", Rect(0, 0, meterWidth, 12));
			Pen.stringCenteredIn("-80", Rect(0, 170, meterWidth, 12));
		});

		if(buses.size > 0) {
			// ins
			StaticText(view, Rect(10, 5, 100, 15))
			.font_(Font.sansSerif(10).boldVariant)
			.string_("Buses");
			busmeters = Array.fill( buses.size, { arg i;
				var comp;
				comp = CompositeView(innerView, Rect(0, 0, meterWidth, 195)).resize_(5);
				StaticText(comp, Rect(0, 180, meterWidth, 15))
				.font_(Font.sansSerif(9).boldVariant)
				.string_(names[i]);
				levelIndic = LevelIndicator( comp, Rect(0, 0, meterWidth, 180) ).warning_(0.9).critical_(1.0)
				.drawsPeak_(true)
				.numTicks_(9)
				.numMajorTicks_(3);
			});
		};
/*
		if((numIns > 0) && (numOuts > 0)) {
			// divider
			UserView(innerView, Rect(0, 0, meterWidth, 180)).drawFunc_( {
				try {
					Pen.color = \QPalette.asClass.new.windowText;
				} {
					Pen.color = Color.white;
				};
				Pen.line(((meterWidth + gapWidth) * 0.5)@0, ((meterWidth + gapWidth) * 0.5)@180);
				Pen.stroke;
			});
		};
*/
		// outs
/*		if(numOuts > 0) {
			StaticText(view, Rect(10 + if(numIns > 0) { (numIns + 2) * (meterWidth + gapWidth) } { 0 }, 5, 100, 15))
			.font_(Font.sansSerif(10).boldVariant)
			.string_("Outputs");
			outmeters = Array.fill( numOuts, { arg i;
				var comp;
				comp = CompositeView(innerView, Rect(0, 0, meterWidth, 195));
				StaticText(comp, Rect(0, 180, meterWidth, 15))
				.font_(Font.sansSerif(9).boldVariant)
				.string_(i.asString);
				levelIndic = LevelIndicator( comp, Rect(0, 0, meterWidth, 180) ).warning_(0.9).critical_(1.0)
				.drawsPeak_(true)
				.numTicks_(9)
				.numMajorTicks_(3);
			});
		};
*/
		this.setSynthFunc(buses);
		startResponderFunc = {this.startResponders};
		this.start;
	}

	setSynthFunc {|buses|
		var numRMSSamps, numRMSSampsRecip;

		synthFunc = {
			//responders and synths are started only once per server
//			var numIns = server.options.numInputBusChannels;
//			var numOuts = server.options.numOutputBusChannels;
			numRMSSamps = server.sampleRate / updateFreq;
			numRMSSampsRecip = 1 / numRMSSamps;

			server.bind( {
				var busSynth;
				if(buses.size> 0, {
					busSynth = SynthDef(server.name ++ "BusLevels", {
						var in = Array.fill(buses.size, {|i| In.kr(buses[i], 1)});
						var trig = Impulse.kr(updateFreq);
						SendReply.kr(trig, "/" ++ server.name ++ "BusLevels", in)
					}).play(RootNode(server), nil, \addToHead);
				});
	/*			if(numOuts > 0, {
					outsynth = SynthDef(server.name ++ "OutputLevels", {
						var in = In.ar(0, numOuts);
						SendPeakRMS.kr(in, updateFreq, 3, "/" ++ server.name ++ "OutLevels")
					}).play(RootNode(server), nil, \addToTail);
				});
*/
				if (serverCleanupFuncs.isNil) {
					serverCleanupFuncs = IdentityDictionary.new;
				};
				serverCleanupFuncs.put(server, {
					busSynth.free;
					//outsynth.free;
					ServerTree.remove(synthFunc, server);
				});
			});
		};
	}

	startResponders {
		var numRMSSamps, numRMSSampsRecip;

		//responders and synths are started only once per server
		numRMSSamps = server.sampleRate / updateFreq;
		numRMSSampsRecip = 1 / numRMSSamps;
		if(buses.size > 0) {
			busresp = OSCFunc( {|msg|
				 {
					try {
						//msg.postln;
						var channelCount = min(msg.size - 3, buses.size);

						channelCount.do {|channel|
							var baseIndex = 3 + channel;
							var peakLevel = msg.at(baseIndex);
							var rmsValue = msg.at(baseIndex);
							var meter = busmeters.at(channel);
							if (meter.notNil) {
								if (meter.isClosed.not) {
									meter.peakLevel = peakLevel;
									meter.value = rmsValue;
								}
							}
						}
					} { |error|
						if(error.isKindOf(PrimitiveFailedError).not) { error.throw }
					};
				}.defer;
			}, ("/" ++ server.name ++ "BusLevels").asSymbol, server.addr).fix;
		};
/*		if(numOuts > 0) {
			outresp = OSCFunc( {|msg|
				 {
					try {
						var channelCount = min(msg.size - 3 / 2, numOuts);

						channelCount.do {|channel|
							var baseIndex = 3 + (2*channel);
							var peakLevel = msg.at(baseIndex);
							var rmsValue = msg.at(baseIndex + 1);
							var meter = outmeters.at(channel);
							if (meter.notNil) {
								if (meter.isClosed.not) {
									meter.peakLevel = peakLevel.ampdb.linlin(dBLow, 0, 0, 1, \min);
									meter.value = rmsValue.ampdb.linlin(dBLow, 0, 0, 1);
								}
							}
						}
					} { |error|
						if(error.isKindOf(PrimitiveFailedError).not) { error.throw }
					};
				}.defer;
			}, ("/" ++ server.name ++ "OutLevels").asSymbol, server.addr).fix;
		}; */
	}

	start {
		if(serverMeterViews.isNil) {
			serverMeterViews = IdentityDictionary.new;
		};
		if(serverMeterViews[server].isNil) {
			serverMeterViews.put(server, List());
		};
		if(serverMeterViews[server].size == 0) {
			ServerTree.add(synthFunc, server);
			if(server.serverRunning, synthFunc); // otherwise starts when booted
		};
		serverMeterViews[server].add(this);
		if (server.serverRunning) {
			this.startResponders
		} {
			ServerBoot.add (startResponderFunc, server)
		}
	}

	stop {
		serverMeterViews[server].remove(this);
		if(serverMeterViews[server].size == 0 and: (serverCleanupFuncs.notNil)) {
			serverCleanupFuncs[server].value;
			serverCleanupFuncs.removeAt(server);
		};

		(buses.size > 0).if( { busresp.free; });
//		(numOuts > 0).if( { outresp.free; });

		ServerBoot.remove(startResponderFunc, server)
	}

	remove {
		view.remove
	}
}

ControlBusMeter {

	var <window, <meterView;

	*new { |server, buses, names, pos|

		var window, meterView;
		pos = pos ? [5, 305];
		window = Window.new("Control Buses",
			Rect(pos[0], pos[1], ControlBusMeterView.getWidth(buses.size), ControlBusMeterView.height),
			false);

		meterView = ControlBusMeterView(server, window, 0@0, buses, names);
		meterView.view.keyDownAction_( { arg view, char, modifiers;
			if(modifiers & 16515072 == 0) {
				case
				 {char === 27.asAscii } { window.close };
			};
		});

		window.front;

		^super.newCopyArgs(window, meterView)

	}
}
