/*
FBDynBus by Tomer Baruch, adapted from MidiCcBus by Jonathan Siemasko

*/

FBDynBus {
	var <>boost, <>expAmt, <>boostNeg, <>refreshRate;
	var <bus, <def, <decline, displayDebugInfo, <>func, <>mappingFunc, <value;

	*new{ arg boost = 0.1, expAmt=0.99, boostNeg=nil, refreshRate=0.1;
		^super
		.newCopyArgs(boost, expAmt, boostNeg, refreshRate)
		.init()
	}

	init{
		func = {};
		value = 0;
//		mappingFunc = { arg x; x/127};
		boostNeg = boostNeg?(boost*0.5);
		bus = Bus.control(Server.default, 1);


		decline = this.runDecline;


//		value !? {value = 0};

	}
	trig {|val|
		value = (value + (val?boost)).min(1.0);
//		value.postln;
		this.bus.set(value);
		func.value(value);
	}

	trigNeg {|val|
		value = (value - (val?boostNeg)).max(0.0);
//		value.postln;
		this.bus.set(value);
		func.value(value);
	}

	setVal {|val|
		value = val;
		this.bus.set(value);
		func.value(value);
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

	free {("freeing dynbus").postln; bus.free; def.free; decline.stop}
	//sets the mappingFunc for the control


	//Returns the current bus value
	//value{^this.value}

	//Returns an OutputProxy mapped to the bus to use it inside of SynthDefs
	//Range is normalized from 0 to 1
	ar{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.ar(bus.ar(1), lagTime), mul, add);}
	kr{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.kr(bus.kr(1), lagTime), mul, add);}
}