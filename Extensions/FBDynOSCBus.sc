/*
FBDynOSCBus by Tomer Baruch, adapted from MidiCcBus by Jonathan Siemasko

*/

FBDynOSCBus {
	var <path, <message, <name, <>boost, <>expAmt, <>boostTime, <>refreshRate;
	var <bus, <def, <decline, displayDebugInfo, <>func, <>mappingFunc, <value;

	*new{ arg path, message, name,  boost = 0.1, expAmt=0.99, boostTime = 0.3, refreshRate=0.1;
		^super
		.newCopyArgs(path, message, name, boost, expAmt, boostTime, refreshRate)
		.init()
	}

	init{
		func = {};
		value = 0;
//		mappingFunc = { arg x; x/127};
		if(path.notNil && name.notNil, {
			bus = Bus.control(Server.default, 1);

			//Set bus value.  Divide by 127 to normalize to 0..1
			def = OSCdef(name, { arg msg;
				msg.postln;
				if ((message.isNil) || (msg[1]==message)) {
					//value = (value + boost).min(1.0);
					var steps = (boostTime/refreshRate).max(1);
					{ steps.do({ value = value+ (boost / steps); refreshRate.yield})}.fork;
					//value.postln;
					//this.bus.set(value);
					func.value(value, msg[1], msg[2]);
				};
			},
			path

			);
			def.permanent = true;
			decline = this.runDecline;

		});
		value !? {value = 0};

	}
	reset {
		this.decline.stop;
		decline = this.runDecline;
	}
	runDecline {
		^{
			{
				value = value*expAmt;
				this.bus.set(value);
				refreshRate.yield;
			}.loop;
		}.fork;
	}

	set { |function| func = function }
	//Set to display debug values to the console
	debug{|setDebug = true| displayDebugInfo = setDebug;}

	//Returns a map for controlling a synth's node inputs
	map{^bus.asMap;}

	free {("freeing"++name).postln; bus.free; def.free; decline.stop}
	//sets the mappingFunc for the control


	//Returns the current bus value
	//value{^this.value}

	//Returns an OutputProxy mapped to the bus to use it inside of SynthDefs
	//Range is normalized from 0 to 1
	ar{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.ar(bus.ar(1), lagTime), mul, add);}
	kr{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.kr(bus.kr(1), lagTime), mul, add);}
}