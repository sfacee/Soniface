b=Buffer.read(s, "/Users/tomerbaruch/Documents/Sonology/Groove/music/Niggas (Acapella).aif")
b.free
e = SCMIRAudioFile( "/Users/tomerbaruch/Documents/Sonology/Groove/music/Niggas (Acapella).aif")
e.extractFeatures
e.plotFeatures(400, 600, 40, true)
m = e.similarityMatrix()
m.plot(4)
e.plotSelfSimilarity(1,4)
e.plotFeatures
b=e.similarityMatrix(100, 2);
b.plot(5,6)
d=e.similarityMatrix(10,2)
n=e.novelty(d, 30)
n.normalize.plot
l=e.findSections();
a=e.similarityMatrix(100);
a.plot(4)
e.plotFeatureTrail
e.plotSelfSimilarity(1,3,1)
e.duration
e.free
"LADSPA_PATH".setenv("/Users/tomerbaruch/Library/Audio/Plug-Ins/Ladspa/");
"LADSPA_PATH".setenv("/Applications/LMMS.app/Contents/lib/lmms/ladspa/");

LADSPA.ladspalist_path
LADSPA.listPlugins;
~file = "/Users/tomerbaruch/Music/Crunch22/Crunch 22 - Mess With Alice's Adventures In Wonderland (AMLP006) (Final Master : WAV) 2/AMLP006 A4 Crunch 22 - Cat v3.wav"
~file = "/Users/tomerbaruch/Music/Crunch22/Crunch 22 - Mess With Alice's Adventures In Wonderland (AMLP006) (Final Master : WAV) 2/AMLP006 B2 Crunch 22 - Confusion v2.wav"
~file = "/Users/tomerbaruch/Music/Crunch22/Crunch 22 - Mess With Alice's Adventures In Wonderland (AMLP006) (Final Master : WAV) 2/AMLP006 B4 Crunch 22 - Lobster v3.wav"

~file = "/Users/tomerbaruch/Downloads/subterranean currents_m.wav"
~file = "/Users/tomerbaruch/Music/SuperCollider Recordings/feedback_151130_213340.mono.2.aiff"
b.free
e = SCMIRAudioFile(~file, [[Loudness],[SpecCentroid],[SpecPcile, 0.95],[SpecPcile, 0.8],[SpecFlatness],[FFTCrest],[FFTCrest, 0, 2000], [FFTCrest, 2000, 10000],[FFTSpread],[FFTSlope],[SensoryDissonance]]);

e.extractFeatures()
e.plotFeatureTrail(0,0.0,2.0)

e.extractBeats();
a=e.beatdata
c=e.tempi
c.plot
e.tempo
b=Buffer.read(s, ~file)
SynthDef(\click, {Out.ar(0, WhiteNoise.ar(EnvGen.ar(Env.perc(0, 0.02), doneAction:2))!2)}).add;
Synth(\click)

(
b.play;
{
	(a.size-1).do({|i|
		Synth(\click);
		(a[i+1]-a[i]).wait;
	});
}.fork
)

LADSPA