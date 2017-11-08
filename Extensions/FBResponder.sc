FBResponder {
	var  <actions, <notifications, <scroll, <posts, <sumFunc, <sums, <video, <reload, <>refreshRate=0.1, <defReactions, <defNotifications;
	var reactions, <>testMessage;

	*new {
		^super
		.newCopyArgs( )
		.init()
	}

	init {

		actions = ();
		notifications = ();
		posts = ();
		sums = ();
		reactions = [\like, \love, \haha, \wow, \sad, \angry, \comment];
		this.setup;

	}

	createDynamicAction { arg name, boost=0.1, expAmt =0.99;
		this.actions.put(name, FBDynBus.new(boost, expAmt));
	}
	createDynamicNotification { arg name, boost=0.1, expAmt =0.99;
		this.notifications.put(name, FBDynBus.new(boost, expAmt));
	}


	setup {
		this.free;
		this.createDynamicAction(\like, 0.12, 0.997);
		this.createDynamicAction(\love, 0.3, 0.99);
		this.createDynamicAction(\haha, 0.3, 0.997);
		this.createDynamicAction(\wow, 0.3, 0.997);
		this.createDynamicAction(\sad, 0.3, 0.997);
		this.createDynamicAction(\angry, 0.3, 0.997);


		this.createDynamicNotification(\like, 0.12);
		this.createDynamicNotification(\love, 0.3);
		this.createDynamicNotification(\haha, 0.3);
		this.createDynamicNotification(\wow, 0.3);
		this.createDynamicNotification(\sad, 0.3);
		this.createDynamicNotification(\angry, 0.3);
		this.createDynamicNotification(\comment, 0.3);
		this.createDynamicNotification(\share, 0.3);
		this.createDynamicNotification(\post, 0.3);
		this.createDynamicNotification(\message, 0.3);
		this.createDynamicNotification(\friend, 0.3);
		this.createDynamicNotification(\reaction, 0.3);

		this.posts.put(\comment, FBDynOSCBus.new(\comment, nil, \comment, 0.1));

		sums[\activity] = FBDynBus(0.1);
		scroll = FBScroll.new(\scroll, \scroll, boost:0.01, expAmt:0.8);
		sumFunc = this.runSumFunc;
		video = FBOSCBus.new(\click, \VIDEO, \video);
		reload = FBOSCBus.new(\reload, nil, \reload);

		//this.createDynamicAction(\comment, \comment, nil);

		defReactions = OSCdef(\fbReaction, {|msg|
			var message = msg[1];
			switch (message)
			{\Like} {actions[\like].trig}
			{\Love} {actions[\love].trig}
			{\Haha} {actions[\haha].trig}
			{\Wow} {actions[\wow].trig}
			{\Sad} {actions[\sad].trig}
			{\Angry} {actions[\angry].trig}

			{\Unlike} {actions[\like].trigNeg}
			{\UnLove} {actions[\love].trigNeg}
			{\UnHaha} {actions[\haha].trigNeg}
			{\UnWow} {actions[\wow].trigNeg}
			{\UnSad} {actions[\sad].trigNeg}
			{\UnAngry} {actions[\angry].trigNeg}

		}, '/click');

		defNotifications = OSCdef(\fbNotification, {|msg|
			var message = msg[1].asString;
			("-"++message++"-").postln;
//			(message=="new message").postln;
			testMessage = message;
			switch (message)
			{"like"} {notifications[\like].trig}
			{"feedback_reaction_generic"} {notifications[\reaction].trig}
			{"feed_comment"} {notifications[\comment].trig}
			{\Love} {notifications[\love].trig}
			{\Haha} {notifications[\haha].trig}
			{\Wow} {notifications[\wow].trig}
			{\Sad} {notifications[\sad].trig}
			{\Angry} {notifications[\angry].trig}
			{\Share} {notifications[\share].trig}
			{\Post} {notifications[\post].trig}
			{"new message"} {notifications[\message].trig}
			{"new friend"} {notifications[\friend].trig}

		}, '/notification');

		defReactions.permanent = true;

		"fbresponder has been setup".postln;

	}

	runSumFunc {
		^{
			{
				var value = actions.collect({|action| action.value}).sum.min(1.0);
				sums[\activity].setVal(value);
				refreshRate.yield;
			}.loop;
		}.fork;
	}


	meter {
		var busArray = [];
		//actions.postln;
		actions.do({|action|
			busArray = busArray ++ action.bus});
		busArray = busArray ++ sums.activity.bus ++ scroll.bus ++ scroll.posBus;
		busArray.postln;
		ControlBusMeter.new(Server.local, busArray, reactions++[\activity, \scrl, \pos], [1500,800]);
	}

	reset {
		sumFunc.stop;
		sumFunc = this.runSumFunc;
		actions.do(_.reset);
		notifications.do(_.reset);
		posts.do(_.reset);
		scroll.reset;
	}

	free {
		actions.do(_.free);
		notifications.do(_.free);
		posts.do(_.free);
		scroll.free;
		defReactions.free;
	}

}