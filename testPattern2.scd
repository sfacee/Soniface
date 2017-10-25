s.useJack
s.boot
(

r.free;
Buffer.freeAll;
~rateBus.free;
~rateBus = Bus.control(s, 1);
r=FBResponder.new;
r.meter;
b=Buffer.read(s, "/Users/tomerbaruch/Music/Crunch22/Crunch 22 - Mess With Alice's Adventures In Wonderland (AMLP006) (Final Master : WAV) 2/AMLP006 A4 Crunch 22 - Cat v3.wav");
c.free;
c=Buffer.alloc(s, 44100*60*5, 2);
~phaseBus = Bus.audio(s, 1);
~rateWowBuf = Buffer.alloc(s, 1024, 1);
~rateSadBuf = Buffer.alloc(s, 1024, 1);
~rateActivityBuf = Buffer.alloc(s, 1024, 1);
~rateScrollBuf = Buffer.alloc(s, 1024, 1);
~inBus = 10;
~outBus = 2;
s.meter;
)
(

SynthDef(\adcVerb, {| inBus = 0, outBus = 0, rtnBus = 106, revTime=2, hfDamping=0.05, preDelay=0, inFilter=0.8, combScale = 1, apScale=1, mixBus |
	var mix = In.kr(mixBus, 1);
	var in = In.ar(inBus, 2);
	var verb = AdCVerb.ar(in, revTime, hfDamping, 2, preDelay, 8, 4, inFilter, combScale:combScale, apScale:apScale);
//	var verb = AdCVerb.ar(in, 4, 0.05, 2, 0, 8, 4, 0.8);
	ReplaceOut.ar(outBus, (verb*(mix/4))+(in*(1-(mix/4))));
//	Out.ar(rtnBus, verb*0.5);
}).add;

SynthDef(\playGrain, {|bufnum, outBus=0, pos=0, dur=0.3, att=0.5, rel=0.5, pan=0.5, rateBus, phaseBus|
//	var scrollRate =BufRd.kr(1, table, In.kr(scrollBus, 1)*BufFrames.kr(table))*scaleScroll;
//	var scrollRate = (In.kr(scrollBus, 1)-0.5)*(-4);
//	var read = PlayBuf.ar(2, bufnum, scrollRate+rate, 1, pos, doneAction:2);
	var rate = In.kr(rateBus, 1);//.poll;
	var phase = (Phasor.ar(1, rate, 0, BufFrames.kr(bufnum))+(pos*BufFrames.kr(bufnum)))%BufFrames.kr(bufnum);
	//var read = PlayBuf.ar(2, bufnum, rate, 1, pos, doneAction:2);
	var read = BufRd.ar(2, bufnum, phase, 1, 4);
	var env = EnvGen.kr(Env.linen(att*dur, dur*(1-att-rel), rel*dur), doneAction:2);
	Out.ar(outBus, read*env);
	//phase.poll;
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
	Out.kr(outBus, rt0*rt1*rt2*rt3);
}).add;

SynthDef(\recordBuf, {|inBus, bufnum, trig, thresh = 0.001, pos = 0, phaseBus|
	var in = In.ar(inBus, 2);
	var delay = DelayN.ar(in, 0.1, 0.1);
	var amplitude = Amplitude.kr(Mix(in), 0.1, 0.2);
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
	BufWr.ar(write , bufnum, phase , 1);
	Out.ar(phaseBus, Select.ar(extPhase>phase, [phase, extPhase]));
	//phase.poll;
//	phaseRate.poll;
//	write.poll;
}).add;


)
(
~attTable = Env.new([0.5, 0, 0], [0.5, 0.5]);
~relTable = Env.new([0.5, 1, 0], [0.5, 0.5]);
~durTable = Env.new([4,0.05], [1], (-4));
~overlapActivityTable = Env.new([0, 1], 1, \sine);

~rateWowTable = Env.new([1, 1.5, -1.5, -2], [0.6, 0, 0.4], [\exp, \lin, \exp]).asBuf(~rateWowBuf);
~rateSadTable = Env.new([1, 0.1], 1, -8).asBuf(~rateSadBuf);
~rateActivityTable = Env.new([0, 0.2, 1, 1, 1.5], [0.001, 0.099,0.7,0.2].normalizeSum, \sine).asBuf(~rateActivityBuf);
~rateScrollTable = Env.new([3, 1, -2], [0.5, 0.5]).asBuf(~rateScrollBuf);
(c.numFrames/11025/2).do({|i| c.setn(i*11025*2, [0.999,0.999])});
r.scroll.boost = 0.01;
r.scroll.expAmt = 0.8;
r.actions.do({|val| val.expAmt = 0.997})

)
~rateWowBuf.plot
~rateScrollBuf.free
~rateSadBuf.plot
~rateActivityBuf.plot
~rateScrollArray.size
~rateScrollTableBuf.plot
~rateScrollTableBuf.free
r.actions.sad.expAmt=0.998
(
var iregularity=0, overlap=1, env=1, rate=1, dur=0.1, scaleScroll = 1, calcDur, pos;
var routeRate, verb, record;
g.do(_.free);
g = Array.fill(2, {Group.tail(s)});
routeRate = Synth.tail(g[0], \setRate4, [\outBus, ~rateBus,
	\src, [r.sums.activity.bus, r.actions.wow.bus, r.actions.sad.bus, r.scroll.bus],
	\tab, [~rateActivityBuf, ~rateWowBuf, ~rateSadBuf, ~rateScrollBuf],
	\scale, [1,1,1,0.1]]);
verb = Synth.tail(g[1], \adcVerb, [\inBus, ~outBus, \outBus, ~outBus, \mixBus, r.actions.love.bus]);
record = Synth(\recordBuf, [\inBus, ~inBus, \bufnum, c, \phaseBus, ~phaseBus]);
r.reset;
r.video.set({record.set(\pos, (r.scroll.pos-0.0003).max(0)*10); "video-----------------------------".postln;});
Tdef(\p, { loop {
	env = 1; //(1-r.actions.sad.value);
	overlap = 1; //~overlapActivityTable[r.sums.activity.value]+(r.actions.sad.value*2)+r.actions.love.value;
	iregularity = (r.actions.haha.value);
	dur = ~durTable[r.actions.like.value+r.actions.wow.value].max(0.05);
	pos = (r.scroll.pos*10)+rrand((iregularity*(-0.01)), (iregularity*0.01));

//	rate = ~rateActivityTable[r.sums.activity.value]*~rateWowTable[r.actions.wow.value]*((1-r.actions.sad.value).max(0.1));
	scaleScroll = 1;
	calcDur = dur*rrand(1-(iregularity*0.5), 1+(iregularity*0.5));

	s.makeBundle(s.latency, {
		Synth.head(g[1], \playGrain, [
			\bufnum, c.bufnum,
			\outBus, 2,
			\pos, pos,
			\rateBus, ~rateBus, //~rateBus, //rate,
			\dur, calcDur*overlap,
			\att, ~attTable.at(env),
			\rel, ~relTable.at(env),
			\phaseBus, ~phaseBus,
		]);
	});
	calcDur.max(0.05).wait;

}}).play;


)
s.meter
c.plot
{Out.ar(2, PlayBuf.ar(2, c))}.play
c.numFrames
r.scroll.pos


0.014544-0.014838400390625

c.zero

/*
states:

Looper: overlap = 1, iregularity = 0, env = 1; play with Dur (between 0.5-1), rate, pos, and a bit with irregularity