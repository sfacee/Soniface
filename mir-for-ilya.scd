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
