(
{|outBus, verbBus, delayBus|
	var betaPan = Pbeta(-1, 1, 0.3, 0.3).asStream;
	var func = {|name, args| Synth(name, [\bufnum, args.samp.bufnum, \dur, args.samp.dur, \outBus, outBus, \pan, betaPan.next])};
	outBus.postln;
~oneShots = (
		playPitch: OneInstancePlayer (\playPitch,
			{|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, sendBus = 100, sendAmt = 0, pan=0|
				var pitchEnv = EnvGen.ar(Env.perc(0, dur/2, 1, (-12)));
				var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, pitchEnv+Rand(0.3, 1.3), doneAction:2))*5);
				//	var env = EnvGen.kr(Env.perc(0.01, dur, 1, 4), doneAction:2);
				var env = EnvGen.kr(Env.linen(0.02, dur*2-0.07, 0.05), doneAction:2);
				//var eq = BPF.ar(signal*env, centroid);
				var out = signal*env;
				Out.ar(outBus, Pan2.ar(out, pan));
				Out.ar(sendBus, out*sendAmt);
			},
			playFunc: {|name, args| Synth(name, [\bufnum, args.samp.bufnum, \dur, args.samp.dur,
				\sendBus, verbBus, \sendAmt, 0.3.coin.if({0.5}, {0}), \outBus, outBus, \pan, betaPan.next]);},
			args: (outBus: outBus),
			minTime: 0.2),

		pitchScat: OneInstancePlayer(\pitchScat,
			{|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, pan=0|
				var pitchEnv = EnvGen.ar(Env.perc(0, dur/2, 1, (-12)));
				var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, pitchEnv+Rand(0.3, 1.3), doneAction:2))*5);
				//	var env = EnvGen.kr(Env.perc(0.01, dur, 1, 4), doneAction:2);
				var env = EnvGen.kr(Env.linen(0.02, dur*2-0.07, 0.05), doneAction:2);
				//var eq = BPF.ar(signal*env, centroid);
				Out.ar(outBus, Pan2.ar(signal*env, pan));
			},
			playFunc: {|name, args|
				var times = (rrand(0.5, 2)*args.times).asInt.postln;
				Routine ({
					times.do({
						var dur = rrand(args.stutDurMin, args.stutDurMax).postln;
						Synth(name, [\bufnum, args.samp.bufnum, \dur, args.samp.dur?0.5, \pan, betaPan.next, \outBus, outBus]);
					dur.wait;
					});
				}).play
			},
			args: (times: 7, stutDurMin: 0.02, stutDurMax: 0.15, outBus: outBus), stopFunc: {|synth| synth.stop}, minTime: 0.2
		),

		texturize: OneInstancePlayer(\texturize,
			{|bufnum, outBus=0, sendBus = 100, pos=0, dur=0.3, pan=0, sendAmt = 0.5, gain = 5, rate=1, amp=0.35|
				//			var phase = (Phasor.ar(1, rate, 0, BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
				//			var read = Limiter.ar(Mix(BufRd.ar(2, bufnum, phase, 1, 4)*5));
				var read = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, loop:1)*5));
				var env = EnvGen.kr(Env.sine(dur), doneAction:2);
				var out = read*env*amp;
				Out.ar(outBus, Pan2.ar(out, pan));
				Out.ar(sendBus, out*sendAmt);
			},
			playFunc: {|name, args|
				var times = (rrand(0.5, 2)*args.times).asInt;
				Routine ({
					times.do({
						var dur = rrand(0.5, 1)*args.samp.bufnum.numFrames/s.sampleRate;
						Synth(name, [\bufnum, args.samp.bufnum, \dur, dur, \pan, betaPan.next, \rate, [0.5, 0.75, 1, 1.5].choose, \outBus, outBus, \sendBus, verbBus, \sendAmt, 0.3]);
						(dur*0.2).wait;
					});
				}).play
			},
			args: (times: 10),
			stopFunc: {|synth| synth.stop},
			minTime: 0.2
		),

		playSamp: OneInstancePlayer(\playSamp,
			{|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, rate=1, pan=0|
				var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, doneAction:2))*5);
				var env = EnvGen.kr(Env.perc(0.01, dur, 1, 0), doneAction:2);
				//	var env = EnvGen.kr(Env.linen(0.02, dur-0.07, 0.05), doneAction:2);
				//var eq = BPF.ar(signal*env, centroid);
				Out.ar(outBus, Pan2.ar(signal*env, pan));
			}, playFunc: func, minTime: 0.2
		),

		playRev: OneInstancePlayer(\playRev,
			{|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, rate=(-1)|
				var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, startPos: dur*SampleRate.ir, doneAction:2))*5);
				var env = EnvGen.kr(Env.perc(dur-0.01, 0.01, 1, 0), doneAction:2);
				//	var env = EnvGen.kr(Env.linen(0.02, dur-0.07, 0.05), doneAction:2);
				//var eq = BPF.ar(signal*env, centroid);
				Out.ar(outBus, Pan2.ar(signal*env, Rand(-1.0, 1)));
			},
			playFunc: func,
			minTime: 0.2
		),

		stutter: OneInstancePlayer(\stutter,
			{|bufnum, outBus = 0, gain=8, dur=0.5, centroid=4000, rate=1, pan=0, curve=0,
				shaperBuf, dist=0.5|
				var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, doneAction:2))*gain);
				var env = EnvGen.kr(Env.perc(0.01, dur, 1, curve), doneAction:2);
				var shaped=BufRd.ar(1, shaperBuf, LinLin.ar(signal,-1.0,1.0,0.0,BufFrames.kr(shaperBuf),0,4));
				var out = LeakDC.ar((shaped*Lag.kr(dist,0.01))+(signal*(1-Lag.kr(dist,0.01))))*env;

				Out.ar(outBus, Pan2.ar(out, pan));
			},
			playFunc: {|name, args|
			var stutDur = rrand(args.stutDurMin, args.stutDurMax);
				var times = (rrand(0.5, 2)*args.times).asInt;
				var pan = betaPan.next;
				var dist = 1.0.rand;
				1.postln;
				Routine ({
					(times-1).do({
						2.postln;
					Synth(name, [\bufnum, args.samp.bufnum, \dur, stutDur,
							\pan, pan, \shaperBuf, ~shaperBuf, \dist, dist, \outBus, outBus]);
						stutDur.wait;
					});
					Synth(name, [\bufnum, args.samp.bufnum, \dur, args.samp.dur, \curve, 8,
						\pan, pan, \shaperBuf, ~shaperBuf, \dist, dist, \outBus, outBus]);
				}).play
			},
			args: (times: 6, stutDurMin: 0.02, stutDurMax: 0.15),
			stopFunc: {|synth| synth.stop},
			minTime: 0.2
		),

		scatter: OneInstancePlayer(\scatter,
			{|bufnum, outBus = 0, gain=5, dur=0.5, centroid=4000, rate=1, pan=0, amp=1, sendBus=100, sendAmt=0|
				var signal = Limiter.ar(Mix(PlayBuf.ar(2, bufnum, rate, doneAction:2))*5);
				var env = EnvGen.kr(Env.perc(0.01, dur, 1, 0), doneAction:2);
				var out = signal*env*amp;
				Out.ar(outBus, Pan2.ar(out, pan));
				Out.ar(sendBus, out*sendAmt);
			},

			playFunc: {|name, args|
			var times = (rrand(0.5, 2)*args.times).asInt;
				var delay = 0.7.coin.if({0.3}, {0});
				var rate = rrand(1.0, 1.5);
				Routine ({
					(times-1).do({
						Synth(name, [\bufnum, args.samp.bufnum,
							\dur, args.samp.dur*rrand(0.5,1),
							\rate, rate*rrand(0.9, 1.2),
							\pan, betaPan.next,
							\amp, rrand(0.3, 1),
							\sendBus, delayBus,
							\sendAmt, delay,
							\outBus, outBus]);
					(args.samp.dur*rrand(0.2,0.6)).wait;
					});
				}).play
			},
			args: (times: 8),
			stopFunc: {|synth| synth.stop},
			minTime: 0.2
		),

		stretch: OneInstancePlayer(\stretch,
		{|bufnum, outBus = 0, sendBus = 100, rate = 0.1, freqScale=1, grainSize=0.03,
				overlaps=3, rnd=0.25, gate = 1, sendAmt = 0.2, gain = 4, pan=0, amp=0.4|
				var signal = Warp1.ar(2, bufnum,
					LFSaw.kr(BufDur.kr(bufnum).reciprocal * rate,1,0.5,0.5),
					freqScale,
					grainSize,
					-1, overlaps, rnd, 4);
				var envGate = EnvGen.kr(Env.adsr(0.01, 0, 1, 0.5), gate, doneAction:2);
				var out = envGate*Limiter.ar(signal*gain)*amp;
				Out.ar(outBus, Pan2.ar(Mix(out), pan));
				Out.ar(sendBus, out*sendAmt);
			},
			playFunc: {|name, args|
				Pmono(name,
					\rate, Pseg( Pseq(args.rate*[1, 1, 0.5]), Pseq(args.samp.dur/args.rate*[0.5,0.5])),
					\bufnum, args.samp.bufnum,
					\dur, 0.01,
					\freqScale, Pseg( Pseq([1, rrand(0.9,1.7), rrand(0.8, 1.1)]), Pseq(args.samp.dur/args.rate*[0.5,0.5])),
					\sendBus, verbBus,
					\sendAmt, 0.3,
					\outBus, outBus,
					\pan, betaPan.next
				).play;
			},
			args: (rate: 0.15),
			stopFunc: {|synth| synth.stop},
			minTime: 0.8
		),

		stretchDown: OneInstancePlayer(\stretchDown, nil,
			playFunc: {|name, args|
			Pmono(\stretch,
					\rate, Pseg( Pseq(args.rate*[1, 0.2]), (args.samp.dur/args.rate)*2),
					\bufnum, args.samp.bufnum,
					\dur, 0.01,
					\freqScale, Pseg( Pseq([rrand(0.8,1.0), rrand(0.25, 0.6)]), (args.samp.dur/args.rate)*2),
					\sendBus, delayBus,
					\sendAmt, 0.3,
					\outBus, outBus,
					\pan, betaPan.next
				).play;
			},
			args: (rate: 0.15),
			stopFunc: {|synth| synth.stop},
			minTime: 0.8
		)
		/*
		ping: OneInstancePlayer(\ping, {|freq = 1000, gate = 1|
		var env = EnvGen.ar(Env.adsr(0, 0, 1, 0.1), gate, doneAction:2);
		Out.ar(0, Pan2.ar(SinOsc.ar(freq, 0, env*EnvGen.kr(Env.perc(0.01, 3), doneAction:2))))});*/
	)
}
)
