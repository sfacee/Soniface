(
var func = {|name, args| Synth(name, [\bufnum, args.samp.bufnum, \dur, args.samp.dur])};
~oneShots = (
	playPitch: OneInstancePlayer(\playPitch, {|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000|
		var pitchEnv = EnvGen.ar(Env.perc(0, dur/2, 1, (-12)));
		var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, pitchEnv+Rand(0.3, 1.3), doneAction:2))*5);
		//	var env = EnvGen.kr(Env.perc(0.01, dur, 1, 4), doneAction:2);
		var env = EnvGen.kr(Env.linen(0.02, dur*2-0.07, 0.05), doneAction:2);
		//var eq = BPF.ar(signal*env, centroid);
		Out.ar(outBus, Pan2.ar(signal*env, Rand(-1.0, 1)));
	}, playFunc: func, minTime: 0.2),

	playSamp: OneInstancePlayer(\playSamp, {|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, rate=1|
		var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, doneAction:2))*5);
		var env = EnvGen.kr(Env.perc(0.01, dur, 1, 0), doneAction:2);
		//	var env = EnvGen.kr(Env.linen(0.02, dur-0.07, 0.05), doneAction:2);
		//var eq = BPF.ar(signal*env, centroid);
		Out.ar(outBus, Pan2.ar(signal*env, Rand(-1.0, 1)));
	}, playFunc: func, minTime: 0.2),

	playRev: OneInstancePlayer(\playRev, {|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, rate=(-1)|
		var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, startPos: dur*SampleRate.ir, doneAction:2))*5);
		var env = EnvGen.kr(Env.perc(dur-0.01, 0.01, 1, 0), doneAction:2);
		//	var env = EnvGen.kr(Env.linen(0.02, dur-0.07, 0.05), doneAction:2);
		//var eq = BPF.ar(signal*env, centroid);
		Out.ar(outBus, Pan2.ar(signal*env, Rand(-1.0, 1).poll));
	}, playFunc: func, minTime: 0.2),

	stutter: OneInstancePlayer(\stutter, {|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, rate=1, pan=0|
		var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, doneAction:2))*5);
		var env = EnvGen.kr(Env.perc(0.01, dur, 1, 0), doneAction:2);
		Out.ar(outBus, Pan2.ar(signal*env, pan));
	},
	playFunc: {|name, args|
		var stutDur = rrand(args.stutDurMin, args.stutDurMax);
		var times = rrand(0.5, 2)*args.times;
		var pan = rrand (-1.0, 1.0);
		1.postln;
		Routine ({
			(times-1).do({
				2.postln;
				Synth(\stutter, [\bufnum, args.samp.bufnum, \dur, stutDur, \pan, pan]);
				stutDur.wait;
			});
			Synth(\stutter, [\bufnum, args.samp.bufnum, \dur, args.samp.dur, \pan, pan]);
		}).play
	},
	args: (times: 6, stutDurMin: 0.02, stutDurMax: 0.15),
	stopFunc: {|synth| synth.stop}, minTime: 0.2
	),

	stretch: OneInstancePlayer(\stretch, {|bufnum, outBus = 0, sendBus = 100, rate = 0.1, freqScale=1, grainSize=0.03, overlaps=3, rnd=0.25, gate = 1, sendAmt = 0.2|
		var signal = Warp1.ar(2, bufnum,
			LFSaw.kr(BufDur.kr(bufnum).reciprocal * rate,1,0.5,0.5),
			freqScale,
			grainSize,
			-1, overlaps, rnd, 4);
		var envGate = EnvGen.kr(Env.adsr(0.01, 0, 1, 0.5), gate, doneAction:2);
		var out = envGate*signal;
		Out.ar(outBus, out);
		Out.ar(sendBus, out*sendAmt);
	},
	playFunc: {|name, args|
		Pmono(name,
			\rate, Pseg( Pseq(args.rate*[1, 1, 0.5]), Pseq(args.samp.dur/args.rate*[0.5,0.5])),
			\bufnum, args.samp.bufnum,
			\dur, 0.01,
			\freqScale, Pseg( Pseq([1, rrand(0.8,1.4), rrand(0.5, 1.1)]), Pseq(args.samp.dur/args.rate*[0.5,0.5])),
			\sendBus, args.sendBus,
		).play;
	},
	args: (rate: 0.1),
	stopFunc: {|synth| synth.stop},
	minTime: 0.8),

	/*
	ping: OneInstancePlayer(\ping, {|freq = 1000, gate = 1|
	var env = EnvGen.ar(Env.adsr(0, 0, 1, 0.1), gate, doneAction:2);
	Out.ar(0, Pan2.ar(SinOsc.ar(freq, 0, env*EnvGen.kr(Env.perc(0.01, 3), doneAction:2))))});*/
)
)
