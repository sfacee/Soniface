FBResponder {
	var  <actions, <scroll, <sumFunc, <sums, <video, <>refreshRate=0.1;
	var reactions;

	*new {
		^super
		.newCopyArgs( )
		.init()
	}

	init {

		actions = ();
		sums = ();
		reactions = [\like, \love, \haha, \wow, \sad, \angry, \comment];
		this.setup;

	}

	createDynamicAction { arg name, path, message, boost=0.1, expAmt =0.99;
		actions[name]=FBDynOSCBus.new(path, message, name, boost, expAmt);

	}


	setup {
		this.free;
		this.createDynamicAction(\like, \click, \Like, 0.12);
		this.createDynamicAction(\love, \click, \Love, 0.3);
		this.createDynamicAction(\haha, \click, \Haha, 0.3);
		this.createDynamicAction(\wow, \click, \Wow, 0.3);
		this.createDynamicAction(\sad, \click, \Sad, 0.3);
		this.createDynamicAction(\angry, \click, \Angry, 0.3);
		this.createDynamicAction(\comment, \comment, nil);
		sums[\activity] = FBDynBus(0.1);
		scroll = FBScroll.new(\scroll, \scroll, boost:0.2, expAmt:0.1);
		sumFunc = this.runSumFunc;
		video = FBOSCBus.new(\click, \Video, \video);
		"fbresponder has been setup".postln;

	}

	runSumFunc {
		^{
			{
				var value = reactions.collect({|key| actions[key].value}).sum.min(1.0);
				sums[\activity].setVal(value);
				refreshRate.yield;
			}.loop;
		}.fork;
	}


	meter {
		var busArray = [];
		actions.postln;
		reactions.do({|val, i|
			val.postln;
			actions[val].postln;
			busArray = busArray ++ actions[val].bus.index});
		busArray = busArray ++ sums.activity.bus ++ scroll.bus ++ scroll.posBus;
		busArray.postln;
		ControlBusMeter.new(Server.local, busArray, reactions++[\activity, \scrl, \pos], [1500,800]);
	}

	resetActions {
		sumFunc.stop;
		sumFunc = this.runSumFunc;
		actions.do(_.reset);
	}


	reset {
		this.resetActions;
		scroll.reset;
	}

	free {
		actions.do(_.free);
		scroll.free;
	}

}