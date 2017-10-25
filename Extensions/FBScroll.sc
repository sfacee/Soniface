/*
FBDynOSCBus by Tomer Baruch, adapted from MidiCcBus by Jonathan Siemasko

*/

FBScroll {
	var <path, <name, <>boost = 0.1, <>expAmt, <>refreshRate;
	var <bus, <posBus, <def, <decline, displayDebugInfo, <>funcVal, <>funcPos, <>mappingFunc, <value, <pos;

	*new{ arg path, name, boost, expAmt=0.99, refreshRate=0.1;
		^super
		.newCopyArgs(path, name, boost, expAmt, refreshRate)
		.init()
	}

	init{
		funcVal = {};
		funcPos = {};
		value = 0.5;
		pos=0;
//		mappingFunc = { arg x; x/127};
		if(path.notNil && name.notNil, {
			bus = Bus.control(Server.default, 1);
			posBus = Bus.control(Server.default, 1);



			//Set bus value.  Divide by 127 to normalize to 0..1
			def = OSCdef(name, { arg msg;
				//msg.postln;
				pos = msg[1]/500000;
				value = (value + (boost*msg[2])).clip(0.0,1);
				//value.postln;
				this.bus.set(value);
				this.posBus.set(pos);
				funcVal.value(value);
				funcPos.value(pos);
			},
			path

			);
			def.permanent = true;
			decline = this.runDecline;

		});
		//value !? {value = 0};

	}
	reset {
		this.decline.stop;
		decline = this.runDecline;
	}
	runDecline {
		^{
			{
			//	value.postln;
				value = ((value-0.5)*expAmt)+0.5;
				this.bus.set(value);
				refreshRate.yield;
			}.loop;
		}.fork;
	}

	set { |functionVal, functionPos| funcVal = functionVal; funcPos = functionPos }
	//Set to display debug values to the console
	debug{|setDebug = true| displayDebugInfo = setDebug;}

	//Returns a map for controlling a synth's node inputs
	map{^bus.asMap;}

	free {bus.free; posBus.free; def.free; decline.stop; }
	//sets the mappingFunc for the control


	//Returns the current bus value
	//value{^this.value}

	//Returns an OutputProxy mapped to the bus to use it inside of SynthDefs
	//Range is normalized from 0 to 1
	ar{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.ar(bus.ar(1), lagTime), mul, add);}
	kr{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.kr(bus.kr(1), lagTime), mul, add);}
}