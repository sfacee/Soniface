s.useJack
s.useMotu
s.boot
(

f.free;
Buffer.freeAll;
~rateBus.free;
~rateBus = Bus.control(s, 1);
f=FBResponder.new;
f.meter;
//b=Buffer.read(s, "/Users/tomerbaruch/Music/Crunch22/Crunch 22 - Mess With Alice's Adventures In Wonderland (AMLP006) (Final Master : WAV) 2/AMLP006 A4 Crunch 22 - Cat v3.wav");
c.free;
c=Buffer.alloc(s, s.sampleRate*60*5, 2);
~phaseBus = Bus.audio(s, 1);
~verbBus = Bus.audio(s, 2);
~rateWowBuf = Buffer.alloc(s, 1024, 1);
~rateSadBuf = Buffer.alloc(s, 1024, 1);
~rateActivityBuf = Buffer.alloc(s, 1024, 1);
~rateScrollBuf = Buffer.alloc(s, 1024, 1);
~inBus = 10;
~outBus = 0;
~shortSamples = Array.fill(50, {(bufnum: Buffer.alloc(s, s.sampleRate*1, 2), stat: \free)});
~maxShortSamples = 0;
~path="/Users/tomerbaruch/Music/Projects/Sonifying Facebook/soniface/";
///(~path++"oneShots.scd").loadPaths;


s.meter;
)
(

SynthDef(\adcVerb, {| inBus = 100, outBus = 0, rtnBus = 106, revTime=2, hfDamping=0.05, preDelay=0, inFilter=0.8, combScale = 1, apScale=1|
//	var mix = In.kr(mixBus, 1);
	var in = In.ar(inBus, 2);
	var verb = AdCVerb.ar(in, revTime, hfDamping, 2, preDelay, 8, 4, inFilter, combScale:combScale, apScale:apScale);
//	var verb = AdCVerb.ar(in, 4, 0.05, 2, 0, 8, 4, 0.8);
	Out.ar(outBus, verb);
//	Out.ar(rtnBus, verb*0.5);
}).add;

SynthDef(\playGrain, {|bufnum, outBus=0, sendBus = 100, pos=0, dur=0.3, att=0.5, rel=0.5, pan=0.5, rateBus, phaseBus, gate = 1, sendAmt = 0|
//	var scrollRate =BufRd.kr(1, table, In.kr(scrollBus, 1)*BufFrames.kr(table))*scaleScroll;
//	var scrollRate = (In.kr(scrollBus, 1)-0.5)*(-4);
//	var read = PlayBuf.ar(2, bufnum, scrollRate+rate, 1, pos, doneAction:2);
//	var rate = Latch.ar(In.kr(rateBus, 1), holdRate);//.poll;
	var rate = In.kr(rateBus, 1);
	var phase = (Phasor.ar(1, rate, 0, BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
	//var read = PlayBuf.ar(2, bufnum, rate, 1, pos, doneAction:2);
	var read = BufRd.ar(2, bufnum, phase, 1, 4);
	var env = EnvGen.kr(Env.linen(att*dur, dur*(1-att-rel), rel*dur), doneAction:2);
	var envadsr = EnvGen.kr(Env.adsr(0, 0, 1, 0.1), gate, doneAction:2);
	var out = read*env*envadsr;
	Out.ar(outBus, out);
	Out.ar(sendBus, out*sendAmt);
	//bufnum.poll;
	//rate.poll;
	//phase.poll;
}).add;

SynthDef(\playGrainFixedRate, {|bufnum, outBus=0, sendBus = 100, pos=0, dur=0.3, att=0.5, rel=0.5, pan=0.5, rate, sendAmt = 0|
	var phase = (Phasor.ar(1, rate, 0, BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
	var read = BufRd.ar(2, bufnum, phase, 1, 4);
	var env = EnvGen.kr(Env.linen(att*dur, dur*(1-att-rel), rel*dur), doneAction:2);
	var out = read*env;
	Out.ar(outBus, out);
	Out.ar(sendBus, out*sendAmt);
}).add;

SynthDef(\setRate4, {|outBus, src=#[100,100,100,100], tab=#[10,10,10,10], scale=#[1,1,1,1]|
	var rt0 =BufRd.kr(1, tab[0], In.kr(src[0], 1).
		linlin(0,1,0.5-(scale[0]/2), 0.5+(scale[0]/2)).clip(0, 0.999)*BufFrames.kr(tab[0]));
	var rt1 =BufRd.kr(1, tab[1], In.kr(src[1], 1).
		linlin(0,1,0.5-(scale[1]/2), 0.5+(scale[1]/2)).clip(0, 0.999)*BufFrames.kr(tab[1]));
	var rt2 =BufRd.kr(1, tab[2], In.kr(src[2], 1).
		linlin(0,1,0.5-(scale[2]/2), 0.5+(scale[2]/2)).clip(0, 0.999)*BufFrames.kr(tab[2]));
	var rt3 =BufRd.kr(1, tab[3], In.kr(src[3], 1).
		linlin(0,1,0.5-(scale[3]/2), 0.5+(scale[3]/2)).clip(0, 0.999)*BufFrames.kr(tab[3]));
	var rate = rt0*rt1*rt2*rt3;
	Out.kr(outBus, rate);
	SendReply.kr(Impulse.kr(10), '/rate', rate);
}).add;

SynthDef(\recordBuf, {|inBus, bufnum, trig, thresh = 0.001, pos = 0, phaseBus,onsetThresh=0.2, gain=5|
	var in = Limiter.ar(In.ar(inBus, 2)*gain);
	var delay = DelayN.ar(in, 0.1, 0.1);
	var amplitude = Amplitude.kr(Mix(in), 0.01, 0.2);
//	var amplitude = LPF.ar(Mix(in).pow(2), 4, 20000);
	var gate = SetResetFF.kr(amplitude > thresh, amplitude < thresh);
	var gateEnv = EnvGen.kr(Env.adsr(0.1, 0, 1, 0.1), gate);
	var change = Changed.kr(pos);
	var changeEnv = EnvGen.kr(Env.new([1,0, 1], [0, 0.1]), change);
	var phaseRate = (gateEnv>0);
	var phase = (Phasor.ar(change, phaseRate, 0, BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
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
	BufWr.ar(write , bufnum, phase , 1);
	Out.ar(phaseBus, Select.ar(extPhase>phase, [phase, extPhase]));
	SendReply.kr(onsets, '/onset', [phase, specCentroid, specEntropy, amplitude]);
//	phase.poll;
//	phaseRate.poll;
//	write.poll;
}).add;

)
(
~attTable = Env.new([0.5, 0, 0], [0.5, 0.5]);
~relTable = Env.new([0.5, 1, 0], [0.5, 0.5]);
~durTable = Env.new([4,0.05], [1], (-4));
~loveVerbTable = Env.new([0, 0.6], [1], [3]);
~overlapActivityTable = Env.new([0, 1], 1, \sine);

~rateWowTable = Env.new([1, 1.5, -1.5, -2], [0.6, 0, 0.4], [\exp, \lin, \exp]).asBuf(~rateWowBuf);

~rateSadTable = Env.new([1, 0.1], 1, -2).asBuf(~rateSadBuf);
~rateActivityTable = Env.new([0, 0.2, 1, 1, 1.5], [0.001, 0.099,0.7,0.2].normalizeSum, \sine).asBuf(~rateActivityBuf);
~rateScrollTable = Env.new([3, 1, -2], [0.5, 0.5]).asBuf(~rateScrollBuf);
c.zero;
(c.numFrames/11025/2).do({|i| c.setn(i*11025*2, [0.999,0.999])});
//f.scroll.boost = 0.01;
//f.scroll.expAmt = 0.8;
f.actions.love.expAmt = 0.994;
//f.actions.love.expAmt = 0.99;
//f.actions.do({|val| val.expAmt = 0.997})

)

(
var routeRate, verb, record, makeLoop;
var posFunc = {|scrollPos, iregularity| (scrollPos*10)+rrand((iregularity*(-0.01)), (iregularity*0.01));};
var durFunc = {|dur, iregularity| dur*rrand(1-(iregularity*0.5), 1+(iregularity*0.5)); };
var currentRate;
var rateReplay = OSCdef.new(\rate, {|msg| currentRate = msg[3]}, '/rate');
var lastOnsetPhase = 0, minOnsetTime = 0.15*s.sampleRate*2, maxOnsetTime = 1*s.sampleRate*2;
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
				"making a new short sample!!!!".postln;
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
g.do(_.free);
g = Array.fill(2, {Group.tail(s)});
routeRate = Synth.tail(g[0], \setRate4, [\outBus, ~rateBus,
	\src, [f.sums.activity.bus, f.actions.wow.bus, f.actions.sad.bus, f.scroll.bus],
	\tab, [~rateActivityBuf, ~rateWowBuf, ~rateSadBuf, ~rateScrollBuf],
	\scale, [1,1,1,0.1]]);
verb = Synth.tail(g[1], \adcVerb, [\inBus, ~verbBus, \outBus, ~outBus]);
record = Synth(\recordBuf, [\inBus, ~inBus, \bufnum, c.bufnum, \phaseBus, ~phaseBus, \onsetThresh, 0.2]);
f.reset;
f.video.set({record.set(\pos, (f.scroll.pos-0.0003).max(0)*10); "video-----------------------------".postln;});

makeLoop = {| numTimes = 1, instrument = \playGrain |
	var outBus = ~outBus, bufnum = c.bufnum, rateBus = ~rateBus;
//	var env, overlap, iregularity, pos, dur, calcDur, firstDur;
	var env = 1; //(1-f.actions.sad.value);
	var overlap = 1; //~overlapActivityTable[f.sums.activity.value]+(f.actions.sad.value*2)+f.actions.love.value;
	var iregularity = (f.actions.haha.value);
	var centerPos = f.scroll.pos;
	var pos = posFunc.value(centerPos, iregularity);
	var dur = ~durTable[f.actions.like.value+f.actions.wow.value].max(0.05);
	var calcDur = durFunc.value(dur, iregularity);
	var firstDur = calcDur;
	var rate = currentRate;
	var synth;
	var makeSynth = {
		var synth;
		s.makeBundle(s.latency, {
			Synth.head(g[1], instrument, [
				\bufnum, bufnum,
				\outBus, outBus,
				\sendBus, ~verbBus,
				\sendAmt, ~loveVerbTable[f.actions.love.value],
				\pos, pos,
				\rateBus, rateBus,
				\rate, rate,
				\dur, calcDur*overlap,
				\att, ~attTable.at(env),
				\rel, ~relTable.at(env),
				\phaseBus, ~phaseBus,
			]);

		});
		synth;
	};
	~numThreads = ~numThreads + 1;
	//"new loop".postln;
	synth = makeSynth.value;
	{
		calcDur.max(0.05).wait;
		if (numTimes>1) {
			(numTimes-1).do({|i|
				//i.postln;
				//"1".postln;
				calcDur = durFunc.value(dur, iregularity);
				pos = posFunc.value(centerPos, iregularity);
				makeSynth.value;
				calcDur.max(0.05).wait;

			});

		};
		~numThreads = ~numThreads - 1;
	}.fork;



	[synth, calcDur];
};
~restartLoop = {
	r.stop;
	if (synth.notNil) {synth.set(\gate, 0)};
	r = Routine({
		var dur=0.5;
		loop {
			# synth, dur = makeLoop.value(1);
			//dur = makeLoop.value(1);
			//dur.postln;
			dur.wait;

		}

	}).play;
};
~restartLoop.value;

f.posts.comment.set({|val, length| "comment".postln; if (~numThreads < 10) {makeLoop.value(length, \playGrainFixedRate)}});
[\like, \love, \haha, \wow, \sad, \angry].do({|key| f.actions[key].set({~restartLoop.value})});
f.notifications.do(_.set({
	~oneShots[~oneShots.keys.choose].play(\samp, ~shortSamples[~maxShortSamples.rand]);
}));

)
(
~info={|i|
	var samp = ~shortSamples[i];
	//samp.buf.play;
	Synth(\playRev, [\bufnum, samp.bufnum, \dur, samp.dur, \rate, -1]);
	"////////////////".postln;
	("sample:"++i).postln;
	("Centroid:"++samp.centroidStart++" / "++samp.centroidEnd).postln;
	("Entropy:"++samp.entropyStart++" / "++samp.entropyEnd).postln;
	("Amplitude:"++samp.amplitudeStart++" / "++samp.amplitudeEnd).postln;

	("duration:"++samp.dur).postln;
}
)
(
{
	50.do({|i|
		~info.value(i);
		1.5.yield;
	});
}.fork
)
f.actions.like.trigNeg
~info.value(3);
~oneShots.playSamp.play(\samp, ~shortSamples[50.rand])
~oneShots.playRev.play(\samp, ~shortSamples[50.rand])
~oneShots.playPitch.play(\samp, ~shortSamples[50.rand])
~oneShots.stutter.play(\samp, ~shortSamples[50.rand])
~oneShots.stretch.play(\samp, ~shortSamples[50.rand])
~oneShots.stretch.stop
~oneShots.stretch.args
c.copyMsg(~shortSamples[0].buf, 0, 0, 100000)
c.get(100, {|msg| msg.postln});
~shortSamples[0].buf.get(100, {|msg| msg.postln});
~shortSamples[0].buf.plot
~record = RecordOutMulti.new(s, inStereo:0);
~record.record;
~record.stop;
~record.free
s.meter
c.plot
{Out.ar(2, PlayBuf.ar(2, c))}.play
c.numFrames
f.scroll.pos
s.record
s.stop
s.makeGui
0.014544-0.014838400390625
f.actions[\like].value=0
c.zero

OSCFunc.trace(true)

~rateWowBuf.plot
~rateScrollBuf.free
~rateSadBuf.plot
~rateActivityBuf.plot
~rateSadTable.plot
~rateScrollArray.size
~rateScrollTableBuf.plot
~rateScrollTableBuf.free
f.actions.sad.expAmt=0.998
~newThresh = 0.2;
~checkBackSamps = 6;
/*
states:

Looper: overlap = 1, iregularity = 0, env = 1; play with Dur (between 0.5-1), rate, pos, and a bit with irregularity