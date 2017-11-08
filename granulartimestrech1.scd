d.free

s.boot;

b = Buffer.read(s, "/Users/tomerbaruch/Music/Projects/Footwork Samples/Blow your whistle/one.wav");
c = Buffer.read(s, "/Users/tomerbaruch/Music/Projects/Footwork Samples/Blow your whistle/two.wav");
d = Buffer.read(s, "/Users/tomerbaruch/Music/Projects/chashmal/ok-short.wav");
// play with rnd, overlap + grainSize for taste
(
~granulator = { |bufnum, rate = 0.1, freqScale=1, grainSize=0.03, overlaps=3, rnd=0.25|
	Pan2.ar(
		Warp1.ar(
			bufnum.numChannels,
			bufnum,
			LFSaw.kr(BufDur.kr(bufnum).reciprocal * rate,1,0.5,0.5),
			freqScale,
			grainSize,
			-1, overlaps, rnd, 4);
	)
}.play(args: [\bufnum, b]);
)


(
var w,f;

w = Window("warp", Rect(400,400,300,125));
w.view.background_(Color.rand);
f = w.addFlowLayout;

EZSlider(w, 280@20, "rate", [0.1,4],  {|sl| ~granulator.set(\rate, sl.value) }, 1);
EZSlider(w, 280@20, "freqScale", [0.1,4],  {|sl| ~granulator.set(\freqScale, sl.value) }, 1);
EZSlider(w, 280@20, "grainSize", [0.01,1],  {|sl| ~granulator.set(\grainSize, sl.value) }, 0.2);
EZSlider(w, 280@20, "overlaps", [1,8,\lin,1],  {|sl| ~granulator.set(\overlaps, sl.value) }, 4);
EZSlider(w, 280@20, "rnd", \unipolar,  {|sl| ~granulator.set(\rnd, sl.value) }, 0.1);

w.front;
)
