(
~initialize = {
	f.free;
	Buffer.freeAll;
	~rateBus.free;
	~rateBus = Bus.control(s, 1);
	f=FBResponder.new;
//	f.meter;
	//b=Buffer.read(s, "/Users/tomerbaruch/Music/Crunch22/Crunch 22 - Mess With Alice's Adventures In Wonderland (AMLP006) (Final Master : WAV) 2/AMLP006 A4 Crunch 22 - Cat v3.wav");
	c.free;
	c=Buffer.alloc(s, s.sampleRate*60*5, 2);
	~phaseBus = Bus.audio(s, 1);
	~verbBus = Bus.audio(s, 2);
	~delayBus = Bus.audio(s, 2);
	~verbOSBus = Bus.audio(s, 2);
	~delayOSBus = Bus.audio(s, 2);
	~rateWowBuf = Buffer.alloc(s, 1024, 1);
	~rateSadBuf = Buffer.alloc(s, 1024, 1);
	~rateActivityBuf = Buffer.alloc(s, 1024, 1);
	~rateScrollBuf = Buffer.alloc(s, 1024, 1);
	~shaperBuf = Buffer.alloc(s,6,1);
	~inBus = ~inBus?10;
	~outBus = 0;
	~outOSBus = 100;
	//~osOutBus = 2;
	~shortSamples = Array.fill(50, {(bufnum: Buffer.alloc(s, s.sampleRate*1, 2), stat: \free)});
	~maxShortSamples = 0;
	~osAmp = 0.5;
	~mainAmp = 0.5;
	~path=~path?"/Users/tomerbaruch/Music/Projects/Sonifying Facebook/soniface/";
	(~path++"oneShots.scd").loadPaths[0].value(~outOSBus, ~verbOSBus, ~delayOSBus);


	~maxThreads = 4;
//	s.meter;
};

~loadBuffers = {
	~defaultsounds=(~path++"feedme-sounds/*").pathMatch.collect({|file| Buffer.read(s, file)});
};

~loadSynthDefs = {
	SynthDef(\routeST, {|inBus=8, outBus=18, amp=1|
		var signal=In.ar(inBus,2);
		Out.ar(outBus,signal*amp);
	}).add;

	SynthDef(\gain, {|inBus= 0, outBus =0, amp=0.5|
		ReplaceOut.ar(outBus, In.ar(inBus, 2)*amp);
	}).add;

	SynthDef(\master, {|inBus = 0, outBus = 0|
		var in = In.ar(inBus, 2);
		in = HPF.ar(in, 20);
		in = Limiter.ar(in);
		in = LeakDC.ar(in);
		ReplaceOut.ar(outBus, in);
	}).add;

	SynthDef(\stDelay, {|inBus = 0, outBus=0, repeat = 0.6, time = 0.16, spread = 1, gate = 1, lpf=2000|
		var inputDry,inputWet,fbLoopIn,fbLoopOut,processingL,processingR,timeLag=time, env;
		var fbNode=LocalIn.ar(1), mono;
		//	env=EnvGen.kr(Env.adsr(0,0,1,1),gate,doneAction:2);
		inputDry=Mix.ar(In.ar(inBus,2));
		inputWet=DelayN.ar(inputDry,5,time,1);
		fbLoopIn=DelayN.ar(fbNode, 5, time)*repeat;
		processingL=(inputWet+LeakDC.ar(LPF.ar(fbLoopIn, lpf) )).tanh;
		processingR=LeakDC.ar(DelayN.ar(processingL,5,time,repeat)).tanh;
		LocalOut.ar(processingR);
		mono = Mix([processingL, processingR])!2;
		Out.ar(outBus,([processingL,processingR]*spread)+(mono*(1-spread)));
	}).add;


	SynthDef(\adcVerb, {| inBus = 100, outBus = 0, rtnBus = 106, revTime=2, hfDamping=0.05, preDelay=0, inFilter=0.8, combScale = 1, apScale=1|
//	var mix = In.kr(mixBus, 1);
		var in = In.ar(inBus, 2);
		var verb = AdCVerb.ar(in, revTime, hfDamping, 2, preDelay, 8, 4, inFilter, combScale:combScale, apScale:apScale);
		//	var verb = AdCVerb.ar(in, 4, 0.05, 2, 0, 8, 4, 0.8);
		Out.ar(outBus, verb);
		//	Out.ar(rtnBus, verb*0.5);
	}).add;

	SynthDef(\playGrain, {|bufnum, outBus=0, sendBus = 100, pos=0, dur=0.3, att=0.5, rel=0.5, pan=0.5, phaseBus,
		scrollBus, scrollTab, scrollScale, rate, gate = 1, sendAmt = 0, shaperBuf, dist = 0, sendBus2=102, sendAmt2=0, amp=1, lpf=15000|
		//	var scrollRate =BufRd.kr(1, scrollTab, In.kr(scrollBus, 1)*BufFrames.kr(table))*scaleScroll;
		//	var scrollRate = (In.kr(scrollBus, 1)-0.5)*(-4);
		//	var read = PlayBuf.ar(2, bufnum, scrollRate+rate, 1, pos, doneAction:2);
		//	var rate = Latch.ar(In.kr(rateBus, 1), holdRate);//.poll;
		var scrollRate = BufRd.kr(1, scrollTab, In.kr(scrollBus, 1).
			linlin(0,1,0.5-(scrollScale/2), 0.5+(scrollScale/2)).clip(0, 0.999)*BufFrames.kr(scrollTab));
		//	var rate = In.kr(rateBus, 1)*rateJit;
		var phase = (Phasor.ar(1, rate*scrollRate, 0, BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
		//var read = PlayBuf.ar(2, bufnum, rate, 1, pos, doneAction:2);
		var read = BufRd.ar(2, bufnum, phase, 1, 4);
		var env = EnvGen.kr(Env.linen(att*dur, dur*(1-att-rel), rel*dur), doneAction:2);
		var envadsr = EnvGen.kr(Env.adsr(0, 0, 1, 0.2), gate, doneAction:2);
		var shaped=BufRd.ar(1, shaperBuf, LinLin.ar(read,-1.0,1.0,0.0,BufFrames.kr(shaperBuf),0,4));
		var out = LeakDC.ar((shaped*Lag.kr(dist,0.01))+(read*(1-Lag.kr(dist,0.01))))*env*envadsr*amp;
		out = LPF.ar(out, lpf);
		Out.ar(outBus, out*(1-((sendAmt+sendAmt2).clip(0,1))));
		Out.ar(sendBus, out*sendAmt);
		Out.ar(sendBus2, out*sendAmt2);
		//bufnum.poll;
		//rate.poll;
		//phase.poll;
	}).add;

	SynthDef(\playGrainFixedRate, {|bufnum, outBus=0, sendBus = 100, pos=0, dur=0.3, att=0.5, rel=0.5, pan=0.5, rate, sendAmt = 0,
		shaperBuf, dist = 0, sendBus2=102, sendAmt2=0, rateJit = 1, amp=1, lpf=15000|
		var phase = (Phasor.ar(1, rate*rateJit, 0, BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
		var read = BufRd.ar(2, bufnum, phase, 1, 4);
		var env = EnvGen.kr(Env.linen(att*dur, dur*(1-att-rel), rel*dur), doneAction:2);
		var shaped=BufRd.ar(1, shaperBuf, LinLin.ar(read,-1.0,1.0,0.0,BufFrames.kr(shaperBuf),0,4));
		var out = LeakDC.ar((shaped*Lag.kr(dist,0.01))+(read*(1-Lag.kr(dist,0.01))))*env*amp;
		out = LPF.ar(out, lpf);
		Out.ar(outBus, out*(1-((sendAmt+sendAmt2).clip(0,1))));
		Out.ar(sendBus, out*sendAmt);
		Out.ar(sendBus2, out*sendAmt2);

	}).add;

	SynthDef(\setRate4, {|outBus, src=#[100,100,100,100], tab=#[10,10,10,10], scale=#[1,1,1,1]|
		var rt0 =BufRd.kr(1, tab[0], In.kr(src[0], 1)*scale[0].clip(0,0.999)*BufFrames.kr(tab[0]));
		var rt1 =BufRd.kr(1, tab[1], In.kr(src[1], 1)*scale[1].clip(0,0.999)*BufFrames.kr(tab[1]));
		var rt2 =BufRd.kr(1, tab[2], In.kr(src[2], 1)*scale[2].clip(0,0.999)*BufFrames.kr(tab[2]));
		var rt3 =BufRd.kr(1, tab[3], In.kr(src[3], 1).
			linlin(0,1,0.5-(scale[3]/2), 0.5+(scale[3]/2)).clip(0, 0.999)*BufFrames.kr(tab[3]));
		var rate = rt0*rt1*rt2*rt3;
		Out.kr(outBus, rate);
		SendReply.kr(Impulse.kr(10), '/rate', rate);
	}).add;

	SynthDef(\recordBuf, {|inBus, bufnum, trig, thresh = 0.001, pos = 0, phaseBus, onsetThresh=0.2, gain=5|
		var in = Limiter.ar(In.ar(inBus, 2)*gain);
		var delay = DelayN.ar(in, 0.2, 0.1);
		var amplitude = Amplitude.kr(Mix(in), 0.01, 0.2);
		//	var amplitude = LPF.ar(Mix(in).pow(2), 4, 20000);
		var gate = SetResetFF.kr(amplitude > thresh, amplitude < thresh);
		var gateEnv = EnvGen.kr(Env.adsr(0.1, 0, 1, 0.1), gate);
		var change = Changed.kr(pos);
		var changeEnv = 1; //EnvGen.kr(Env.new([1,0, 1], [0, 0.1]), change);
		var phaseRate = BufRateScale.kr(bufnum); //*(gateEnv>0);
		//	var phase = (Phasor.ar(change, phaseRate,  0 , BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
		var phase = Phasor.ar(change, phaseRate, 0 , BufFrames.kr(bufnum), pos*BufFrames.kr(bufnum));
		var read = BufRd.ar(2, bufnum, phase);
		var env = gateEnv*changeEnv;
		var extPhase = In.ar(phaseBus, 1);
		//env.poll;
		//	var phaseCalc = phase%BufFrames.kr(bufnum);
		var write = delay*env + (read*(1-env));
		var chain = FFT( LocalBuf(1024), Mix(write));
		var onsets = Onsets.kr(chain, onsetThresh);
		var specCentroid = SpecCentroid.kr(chain);
		var specEntropy = SpectralEntropy.kr(chain, 1024);
		var rms = (RunningSum.kr(amplitude, 1000) /1000).ampdb;
		var tooLoud = (rms - (-15)).linexp(0, 15, 1, 0.177);
		BufWr.ar(write*tooLoud , bufnum, phase , 1);
		Out.ar(phaseBus, Select.ar(extPhase>phase, [phase, extPhase]));
		SendReply.kr(onsets, '/onset', [phase, specCentroid, specEntropy, amplitude]);
		//tooLoud.poll;
		//	Out.ar(0, SinOsc.ar(phase*0.001, 0, 0.1));
		//	(phase*0.001).poll;
		//	phaseRate.poll;
		//	write.poll;
	}).add;

	SynthDef(\playIn, {|inBus, outBus, amp=0.3, gain=5, gate=1|
		Out.ar(outBus, Limiter.ar(In.ar(inBus, 2)*amp*Lag.kr(gate)));
	}).add;
};
~setTables = {
	~attTable = Env.new([0.5, 0, 0], [0.5, 0.5]);
	~relTable = Env.new([0.5, 1, 0], [0.5, 0.5]);
	//~durTable = Env.new([4,0.05], [1], (-4));
	~durTable = [4, 4, 3, 2,  2, 1, 2/3, 1/2, 1/3, 1/4, 1/6, 1/8, 1/12, 1/16, 1/24, 1/32];
	~loveVerbTable = Env.new([0, 0.6], [1], \lin);
	~loveDelayTable = Env.new([0,0,0.6], [1], [1]);
	~angryDistTable = Env.new([0, 1], [1]);
	~overlapActivityTable = Env.new([0, 1], 1, \sine);
	~timesToDur = Env.new([10, 50, 120,150], [5, 5, 40]);
	~rateWowTable = Env.new([1, 1, -1, -2], [0.1, 0.001, 0.899], [\lin, \lin, 4]).asBuf(~rateWowBuf);

	~rateSadTable = Env.new([1, 0.1], 1, -3).asBuf(~rateSadBuf);
	~rateActivityTable = Env.new([0, 0.2, 1, 1, 1.5], [0.001, 0.099,0.7,0.2].normalizeSum, \sine).asBuf(~rateActivityBuf);
	~rateScrollTable = Env.new([3, 1, -2], [0.5, 0.5]).asBuf(~rateScrollBuf);
	c.zero;
	(c.numFrames/11025/2).do({|i| c.setn(i*11025*2, [0.999,0.999])});
	//f.scroll.boost = 0.01;
	//f.scroll.expAmt = 0.8;
	f.actions.love.expAmt = 0.992;
	f.actions.angry.expAmt = 0.997;
	f.actions.haha.expAmt = 0.992;
	f.actions.wow.expAmt = 0.993;
	f.actions.sad.expAmt = 0.25;
	f.actions.sad.boost = 0.25;
	f.actions.sad.expFunc = {|val, expAmt| (val-expAmt).max(0)};
	f.actions.sad.refreshRate=20;
	f.sums.activity.expAmt = 0.997;
	f.sums.activity.boost = 0.12;

	//f.actions.love.expAmt = 0.99;
	//f.actions.do({|val| val.expAmt = 0.997})
	~shaperBuf.setn(0,[-1,0.6,-0.2,0.2,-0.6,1]);
	~bpm=100;
};

~setDefaultBuffer = {
	var pos=0;
	while {pos<c.numFrames} {
		var buf = ~defaultsounds.choose;
		buf.copyData(c, pos, 0);
		pos = pos + buf.numFrames;
		pos.postln;
	};
};


~startProcess = {

	var routeRate, verb, delay, limiter, verbOS, delayOS, route, record, makeLoop;
	var posFunc = {|scrollPos, iregularity| (scrollPos*10)+rrand((iregularity*(-0.01)), (iregularity*0.01));};
	var durFunc = {|dur, iregularity| dur*rrand(1-(iregularity*0.5), 1+(iregularity*0.5)); };
	var rateJitFunc = {|iregularity| rrand(1-(iregularity*0.2), 1+(iregularity))};
	var currentRate = 1;
	//var rateReplay = OSCdef.new(\rate, {|msg| currentRate = msg[3]}, '/rate');
	var lastOnsetPhase = 0, minOnsetTime = 0.25*s.sampleRate*2, maxOnsetTime = 3*s.sampleRate*2;
	var minEntropyDifference = 0.05, minCentroidDifference=3, minAmplitude = 0.05;
	var lastShortBuf = 0;
	var lastAmplitude = 0, lastCentroid = 0, lastEntropy = 0;
	var synth;
	var onsetsReplay = OSCdef.new(\onsets, {|msg|
		// Possible problem - two of these start at the same time and work on the same buffer;
		var phase = msg[3];
		var phaseDifference = phase - lastOnsetPhase;
		var centroid = msg[4], entropy = msg[5].explin(0.1, 50, 0.0, 1), amplitude = msg[6];
		//msg.postln;
		//	("onset phase:"++phaseDifference).postln;
		if ((phaseDifference>=minOnsetTime) && (phaseDifference<=maxOnsetTime)) {
			var samp = ~shortSamples[lastShortBuf];
			var prevSamps = Array.fill(~checkBackSamps, {|i| ~shortSamples[(lastShortBuf-(i+1))%~shortSamples.size]});
			var isDifferent=true;
			//		samp.postln;
			//		prevSamp.postln;
			if (lastAmplitude>=minAmplitude) {
				"amplitude is good".postln;
				prevSamps.do({|prevSamp|
					var centroidDif = (lastCentroid.cpsmidi - (prevSamp.centroidStart?0).cpsmidi).abs;
					var entropyDif = (lastEntropy - (prevSamp.entropyStart?0)).abs;
					if (
						(centroidDif*entropyDif<~newThresh)
					) {
						isDifferent = false;
						("samp is too similar to "++prevSamp.bufnum).postln;
						("centDif:"++centroidDif++", entDif:"++entropyDif++", mul:"++(centroidDif*entropyDif)).postln;
					}
				});
				if (isDifferent) {
					samp.stat = \busy;
					samp.bufnum.zero;
					c.copyData(samp.bufnum, 0, lastOnsetPhase, phaseDifference);
					samp.centroidStart = lastCentroid;
					samp.centroidEnd = centroid;
					samp.entropyStart = lastEntropy;
					samp.entropyEnd = entropy;
					samp.amplitudeStart = lastAmplitude;
					samp.amplitudeEnd = amplitude;
					samp.dur = phaseDifference/s.sampleRate/2;
					samp.stat = \good;
					("making a new short sample!!! dur:"++samp.dur).postln;

					//samp.bufnum.play;
					lastShortBuf = lastShortBuf + 1;
					~maxShortSamples = (~maxShortSamples + 1).min(~shortSamples.size);
					if ( lastShortBuf >= ~shortSamples.size ) {lastShortBuf = 0};
					("next buffer is:"++lastShortBuf).postln;
				};
			} {"amp too low".postln};
		};
		lastOnsetPhase = phase;
		lastCentroid = centroid;
		lastEntropy = entropy;
		lastAmplitude = amplitude;

	}, '/onset');
	~numThreads = 0;
	~threads = ();
	g.do(_.free);
	g = Array.fill(2, {Group.tail(s)});
	/*
	routeRate = Synth.tail(g[0], \setRate4, [\outBus, ~rateBus,
	\src, [f.sums.activity.bus, f.actions.wow.bus, f.actions.sad.bus, f.scroll.bus],
	\tab, [~rateActivityBuf, ~rateWowBuf, ~rateSadBuf, ~rateScrollBuf],
	\scale, [1,1,0,0.1]]);
	*/

	~verb = Synth.tail(g[1], \adcVerb, [\inBus, ~verbBus, \outBus, ~outBus, \revTime, 5]);
	~delay = Synth.tail(g[1], \stDelay, [\inBus, ~delayBus, \outBus, ~outBus, \time, 0.45, \repeat, 0.9]);
	~verbOS = Synth.tail(g[1], \adcVerb, [\inBus, ~verbOSBus, \outBus, ~outOSBus]);
	~delayOS = Synth.tail(g[1], \stDelay, [\inBus, ~delayOSBus, \outBus, ~outOSBus]);
	~mainGain = Synth.tail(g[1], \gain, [\inBus, ~outBus, \outBus, ~outBus, \amp, ~mainAmp]);
	~limiterOS =  Synth.tail(g[1], \master, [\inBus, ~outOSBus, \outBus, ~outOSBus]);
	~routeOS = Synth.tail(g[1], \routeST, [\inBus, ~outOSBus, \outBus, ~outBus, \amp, ~osAmp]);
	~limiterMain = Synth.tail(g[1], \master, [\inBus, ~outBus, \outBus, ~outBus]);

	~record = Synth(\recordBuf, [\inBus, ~inBus, \bufnum, c.bufnum, \phaseBus, ~phaseBus, \onsetThresh, 0.2]);
	//Ndef(\playIn, {Out.ar(~outBus, In.ar(~inBus, 2))});
	~playIn=Synth(\playIn, [\inBus, ~inBus, \outBus, ~outBus, \gate, 0, \amp, 0.3]);
	f.reset;
	f.video.set({
		~record.set(\pos, (f.scroll.pos-0.0003).max(0)*10);
		~playIn.set(\gate, 1);
		"video-----------------------------".postln;
	});

	makeLoop = {| numTimes = 1, instrument = \playGrain, killSynth = true |
		var outBus = ~outBus, bufnum = c.bufnum, rateBus = ~rateBus;
		//	var env, overlap, iregularity, pos, dur, calcDur, firstDur;
		var env = 1; //(1-f.actions.sad.value);
		var overlap = 1+f.actions.haha.value;
		var iregularity = f.actions.haha.value;
		var centerPos = f.scroll.pos;
		var pos = posFunc.value(centerPos, iregularity);
		//	var dur = ~durTable[f.actions.like.value+f.actions.wow.value].max(0.05);
		var dur = ~durTable[(f.actions.like.value+(f.actions.wow.value/3)+f.actions.haha.value).linlin(0,1,0, ~durTable.size).asInt]*~bpm.bpmms;
		var calcDur = durFunc.value(dur, iregularity);
		var firstDur = calcDur;
		var rate = (
			~rateActivityTable[f.sums.activity.value] *
			~rateWowTable[f.actions.wow.value] *
			~rateSadTable[f.actions.sad.value] ).postln;
		//	var rateSad = ~rateSadTable[f.actions.sad.value];
		var rateJit = rateJitFunc.value(iregularity);
		var dist = ~angryDistTable[f.actions.angry.value];
		var sendVerb = ~loveVerbTable[f.actions.love.value+(f.actions.sad.value*2)];
		var sendDelay = ~loveDelayTable[f.actions.love.value];
		var amp =1;
		var lpf = 15000;
		var localSynth, currentThread;
		var makeSynth = {
			//		var localSynth;
			s.makeBundle(s.latency, {
				if (killSynth) {synth.set(\gate, 0);};
				localSynth = Synth.head(g[1], instrument, [
					\bufnum, bufnum,
					\outBus, outBus,
					\sendBus, ~verbBus,
					\sendAmt, sendVerb,
					\pos, pos,
					\sendBus2, ~delayBus,
					\sendAmt2, sendDelay,
					\pos, pos,
					\scrollBus, f.scroll.bus,
					\scrollTab, ~rateScrollBuf,
					\scrollScale, if (killSynth) {0.1} {0},
					\rate, rate*rateJit, //calcRate,
					\dur, calcDur*overlap,
					\att, ~attTable.at(env),
					\rel, ~relTable.at(env),
					\phaseBus, ~phaseBus,
					\shaperBuf, ~shaperBuf,
					\dist, dist,
					\amp, amp,
					\lpf, lpf
				]);
				if (killSynth) {synth = localSynth};
			});
			//	synth;
		};
		//"new loop".postln;
		//synth = makeSynth.value;
		//numTimes.postln;
		makeSynth.value;
		if (numTimes>1) {
			numTimes = (~timesToDur[numTimes]/dur).asInt.postln;
			~numThreads = ~numThreads +1;
			currentThread = 10000000.rand;
			~threads[currentThread] = {
				calcDur.max(0.05).wait;
				(numTimes-1).do({|i|
					//i.postln;
					//"1".postln;
					calcDur = durFunc.value(dur, iregularity);
					pos = posFunc.value(centerPos, iregularity);
					rateJit = rateJitFunc.value(iregularity);
					amp = amp * dur.linlin(0.1, 2, 0.995, 0.96);
					lpf = lpf * dur.linlin(0.1, 2, 0.993, 0.91);
					makeSynth.value;
					calcDur.max(0.05).wait;

				});


				~numThreads = ~numThreads - 1;
				~threads[currentThread]=nil;
			}.fork;
		};
		calcDur;
	};
	~restartLoop = {
		//	var tempSynth = nil;
		~playIn.set(\gate, 0);
		r.stop;
		//	synth.postln;
		//	if (synth.notNil) {tempSynth = synth};
		r = Routine({
			var dur=0.5;
			loop {
				dur = makeLoop.value(1);
				//dur = makeLoop.value(1);
				//dur.postln;
				dur.wait;

			}

		}).play;
		//	if (tempSynth.notNil) {tempSynth.set(\gate, 0)};
	};
	~stopLoop = {
		if (r.notNil) {r.stop; r=nil;};
		s.makeBundle(s.latency, {synth.set(\gate, 0);});
	};
	~removeThread = {
		if (~threads.size>0) {
			var key = ~threads.keys.choose;
			~threads[key].stop;
			~threads[key]=nil;
			~numThreads = (~numThreads-1).max(0);
		};
	};
	~stopOrRemove = {
		if (r.notNil) {~stopLoop.value} {~removeThread.value};
	};

	~restartLoop.value;
	~playOneShot = {|key|
		if (~maxShortSamples>0) {
			~oneShots[key].play(\samp, ~shortSamples[~maxShortSamples.rand]);
		}
	};

	~resetSystem = {
		~stopLoop.value;
		4.do({~removeThread.value});
		c.zero;
		(c.numFrames/11025/2).do({|i| c.setn(i*11025*2, [0.999,0.999])});
		f.notifications.do(_.zero);
		f.actions.do(_.zero);
		f.posts.do(_.zero);
	};

	f.posts.do(_.set({|val| "comment now".postln;
		if (~numThreads > ~maxThreads) {~removeThread.value};
		makeLoop.value(((val?8).max(3)).postln, \playGrain, false);
		~stopLoop.value;
		~playIn.set(\gate, 0);
	}));
	[\like, \love, \haha, \wow, \sad, \angry].do({|key| f.actions[key].set({~restartLoop.value}, {~stopOrRemove.value})});
	f.notifications.do(_.set({~playOneShot.value([\playSamp, \playRev].choose)}));
	f.notifications.like.set({~playOneShot.value(\pitchScat)});
	f.notifications.love.set({~playOneShot.value(\texturize)});
	f.notifications.haha.set({~playOneShot.value(\scatter)});
	f.notifications.wow.set({~playOneShot.value(\stretch)});
	f.notifications.sad.set({~playOneShot.value(\stretchDown)});
	f.notifications.angry.set({~playOneShot.value(\stutter)});
	f.actions.angry.set({
		if (~maxShortSamples>0) {
			~oneShots.stutter.play(\samp, ~shortSamples[~maxShortSamples.rand], \times, 2.5, \stutDurMax, 0.08);
		};
		~restartLoop.value
	}, {~stopOrRemove.value});
	/*f.actions.sad.set({
	[\like, \love, \haha].do({|key|
	//	if (f.actions[key].value>0.1) {f.actions[key].setVal(0.08)} {f.actions[key].setVal(f.actions[key].value*0.8)};
		f.actions[key].zero;
	});
	~restartLoop.value
	}, {~stopOrRemove.value}); */
	f.sums.notifications.set({|val| ~bpm = 100 + val.linexp(0,1, 1, 30).round(2)});
	{
		{
			~bpm = 100 + (f.sums.notifications.value?0).linexp(0,1, 0.5, 30).round(2);
			("bpm:"++~bpm).postln;
			5.yield;
		}.loop;
	}.fork;
};
)

