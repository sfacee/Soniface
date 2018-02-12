/*
FBDynBus by Tomer Baruch, adapted from MidiCcBus by Jonathan Siemasko

*/

FBDynBus {
	var <>boost, <>expAmt, <>boostNeg, <>refreshRate;
	var <bus, <def, <decline, <>funcOn, <>funcOff, <>mappingFunc, <>value, <>expFunc;

	*new{ arg boost = 0.1, expAmt=0.99, boostNeg=nil, refreshRate=0.1;
		^super
		.newCopyArgs(boost, expAmt, boostNeg, refreshRate)
		.init()
	}

	init{
		funcOn = {};
		funcOff = {};
		value = 0;
//		mappingFunc = { arg x; x/127};
		expFunc = {|val, expAmt| val*expAmt};
		boostNeg = boostNeg?(boost);
		bus = Bus.control(Server.default, 1);


		//decline = this.runDecline;


//		value !? {value = 0};

	}


	setVal {|val|
		value = val;
		this.bus.set(value);
		funcOn.value(value);
		this.reset;
	}

	trig {|val|
		this.setVal((value + (val?boost)).min(1.0));
	}

	trigNeg {|val|
		value = (value - (val?boostNeg)).max(0.0);
//		value.postln;
		this.bus.set(value);
		funcOff.value(value);
	}

	zero {
		value = 0;
		this.bus.set(value);
		this.decline.stop;
	}
	reset {
		this.decline.stop;
		decline = this.runDecline;
	}
	runDecline {
		^{
			refreshRate.yield;
			{
				value = expFunc.value(value, expAmt);
				this.bus.set(value);
				refreshRate.yield;
			}.loop;
		}.fork;
	}

	set { |functionOn, functionOff| funcOn = functionOn; funcOff = functionOff }
	free {("freeing dynbus").postln; bus.free; def.free; decline.stop}
	//sets the mappingFunc for the control


	//Returns the current bus value
	//value{^this.value}

	//Set to display debug values to the console
	//	debug{|setDebug = true| displayDebugInfo = setDebug;}

	//Returns a map for controlling a synth's node inputs
	//	map{^bus.asMap;}



	//Returns an OutputProxy mapped to the bus to use it inside of SynthDefs
	//Range is normalized from 0 to 1
	//	ar{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.ar(bus.ar(1), lagTime), mul, add);}
	//	kr{|mul=1, add=0, lagTime = 0.1|^MulAdd(Lag.kr(bus.kr(1), lagTime), mul, add);}
}