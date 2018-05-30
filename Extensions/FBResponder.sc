FBResponder {
	var  <actions, <notifications, <scroll, <posts, <sumFunc, <sums, <video, <reload, <>refreshRate=0.1, <defReactions, <defNotifications, <defPosts;
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
		reactions = [\like, \love, \haha, \wow, \sad, \angry];
		this.setup;

	}

	createDynamicAction { arg name, boost=0.1, expAmt =0.99;
		this.actions.put(name, FBDynBus.new(boost, expAmt));
	}
	createDynamicNotification { arg name, boost=0.1, expAmt =0.99;
		this.notifications.put(name, FBDynBus.new(boost, expAmt));
	}
	createDynamicPost { arg name, boost=0.1, expAmt =0.99;
		this.posts.put(name, FBDynBus.new(boost, expAmt));
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
		this.createDynamicNotification(\other, 0.1);

//		this.posts.put(\comment, FBDynOSCBus.new(\comment, nil, \comment, 0.1));
//		this.posts.put(\comment, FBDynOSCBus.new(\post, \Comment, \comment, 0.1));
//		this.posts.put(\post, FBDynOSCBus.new(\post, \Post, \post, 0.1));
//		this.posts.put(\share, FBDynOSCBus.new(\post, "post_click", \share, 0.1));

		this.createDynamicPost(\comment, 0.1);
		this.createDynamicPost(\post, 0.1);
		this.createDynamicPost(\share, 0.1);

		sums[\activity] = FBDynBus(0.12, 0.997);
		sums[\notifications] = FBDynBus(0.08, 0.996);
		scroll = FBScroll.new(\scroll, \scroll, boost:0.01, expAmt:0.8);
//		sumFunc = this.runSumFunc;
		video = FBOSCBus.new(\video, \click, \video);
		reload = FBOSCBus.new(\reload, nil, \reload);

		//this.createDynamicAction(\comment, \comment, nil);

		defReactions = OSCdef(\fbReaction, {|msg|
			var message = msg[1];
			switch (message)
			{\Like} {sums.activity.trig; actions[\like].trig}
			{\Love} {sums.activity.trig; actions[\love].trig}
			{\Haha} {sums.activity.trig; actions[\haha].trig}
			{\Wow} {sums.activity.trig; actions[\wow].trig}
			{\Sad} {sums.activity.trig; actions[\sad].trig}
			{\Angry} {sums.activity.trig; actions[\angry].trig}

			{\Unlike} {sums.activity.trigNeg; actions[\like].trigNeg}
			{\UnLove} {sums.activity.trigNeg; actions[\love].trigNeg}
			{\UnHaha} {sums.activity.trigNeg; actions[\haha].trigNeg}
			{\UnWow} {sums.activity.trigNeg; actions[\wow].trigNeg}
			{\UnSad} {sums.activity.trigNeg; actions[\sad].trigNeg}
			{\UnAngry} {sums.activity.trigNeg; actions[\angry].trigNeg}

			{"לייק".asSymbol} {sums.activity.trig; actions[\like].trig}
			{"אהבה".asSymbol} {sums.activity.trig; actions[\love].trig}
			{"חחח".asSymbol} {sums.activity.trig; actions[\haha].trig}
			{"וואו".asSymbol} {sums.activity.trig; actions[\wow].trig}
			{"עצב".asSymbol} {sums.activity.trig; actions[\sad].trig}
			{"כעס".asSymbol} {sums.activity.trig; actions[\angry].trig}

			{"Unלייק".asSymbol} {sums.activity.trigNeg; actions[\like].trigNeg}
			{"Unאהבה".asSymbol} {sums.activity.trigNeg; actions[\love].trigNeg}
			{"Unחחח".asSymbol} {sums.activity.trigNeg; actions[\haha].trigNeg}
			{"Unוואו".asSymbol} {sums.activity.trigNeg; actions[\wow].trigNeg}
			{"Unעצב".asSymbol} {sums.activity.trigNeg; actions[\sad].trigNeg}
			{"Unכעס".asSymbol} {sums.activity.trigNeg; actions[\angry].trigNeg}

//		}, '/click');
		}, '/reaction');
		defReactions.permanent = true;


		defNotifications = OSCdef(\fbNotification, {|msg|
			var message = msg[1].asString;
			var flag = true;
			("-"++message++"-").postln;
			sums.notifications.trig;
//			(message=="new message").postln;
//			testMessage = message;
			switch (message)
			{"like"} {notifications[\like].trig; flag = false}
			{"feedback_reaction_generic"} {notifications[\reaction].trig; flag=false;}
			{"unknown_reaction"} {notifications[\reaction].trig; flag=false}
			{"feed_comment"} {notifications[\comment].trig; flag = false}
			{"photo_comment"} {notifications[\comment].trig; flag = false}
			{"group_comment_replay"} {notifications[\comment].trig; flag = false}
			{"Love"} {notifications[\love].trig; flag = false}
			{"Haha"} {notifications[\haha].trig; flag = false}
			{"Wow"} {notifications[\wow].trig; flag = false}
			{"Sad"} {notifications[\sad].trig; flag = false}
			{"Angry"} {notifications[\angry].trig; flag = false}
			{"story_reshare"} {notifications[\share].trig; flag = false}
			{"wall"} {notifications[\post].trig; flag = false}
			{"new message"} {notifications[\message].trig; flag = false}
			{"new friend"} {notifications[\friend].trig; flag = false};
			if (flag) {notifications[\other].trig};
		}, '/notification');
		defNotifications.permanent = true;

		defPosts = OSCdef(\fbPost, {|msg|
			var message = msg[1].asString;
			("-"++message++"-").postln;
//			(message=="new message").postln;
//			testMessage = message;
			switch (message)
			{"Comment"} {posts[\comment].setVal((msg[2]?1).asInt)}
			{"Post"} {posts[\post].setVal((msg[2]?1).asInt)}
			{"post_click"} {posts[\post].setVal((msg[2]?1).asInt)}
		}, '/post');

		defPosts.permanent = true;

		"fbresponder has been setup".postln;

	}

	/*runSumFunc {
		^{
//			{
			sums.activity.zero;
			//sums[\activity].setVal(actions.collect({|action| action.value}).sum.min(1.0));
			//	sums[\notifications].setVal(notifications.collect({|action| action.value}).sum.min(1.0));
	//			refreshRate.yield;
	//		}.loop;

		}.fork;
	}
*/

	meter {
		var busArray = [];
		//actions.postln;
		reactions.do({|key|
			busArray = busArray ++ actions[key].bus
		});
		busArray = busArray ++ posts.comment.bus ++ sums.activity.bus ++ scroll.bus ++ scroll.posBus;
		busArray.postln;
		ControlBusMeter.new(Server.local, busArray, reactions++[\comment, \activity, \scrl, \pos], [1500,800]);
	}

	reset {
//		sumFunc.stop;
//		sumFunc = this.runSumFunc;
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
		defNotifications.free;
		defPosts.free;
	}

}