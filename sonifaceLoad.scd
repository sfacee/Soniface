(
// Make sure that in your system preferences the audio input and output is set to the external interface.
// Then put your cursor somewhere here and press Cmd+Enter
// Then go to system preferences and change audio output to the headphones out and physically plug headphones out to the first two inputs of your interface.
//s.useMotu;
//s.useJack;
~korg = true;
{
	var c;
	~path="/Users/tomerbaruch/Music/Projects/Sonifying Facebook/soniface/"; // change this to the current folder of the supercollider app
	(~path++"soniface2.scd").loadPaths;
	Server.local.options.numInputBusChannels = 8;
	Server.local.options.numOutputBusChannels = 8;
	~inBus = 10;
	"booting server".postln;
	s.bootSync(c);
	3.wait;
	if (~korg) {k = KORGMapper.new};
	"initializing".value;
	~initialize.value;
	s.sync(c);
	3.wait;
	"loading synthdefs and buffers".postln;
	~loadSynthDefs.value;
	~loadBuffers.value;
	s.sync(c);
	3.wait;
	"setting tables and default buffer".postln;
	~setTables.value;
	~setDefaultBuffer.value;
	s.sync(c);
	if (~korg) {
		k.sliders[0].set({|val| ~mainAmp = val.linexp(0,1,0.001, 1); ~mainGain.set(\amp, ~mainAmp);});
		k.sliders[1].set({|val| ~osAmp = val.linexp(0,1,0.001, 1); ~routeOS.set(\amp, ~osAmp);});
	};
	5.wait;
	"starting app".postln;
	~startProcess.value;
}.fork;
)

(
// run this (cmd+enter) to see meters:
s.meter;
f.meter;
)

 ~osAmp=0.5;~routeOS.set(\amp, ~osAmp)

Ndef(\playIn).clear
Ndef(\playIn).play
Ndef(\playIn).clear
Ndef.clear
Ndef(\playIn, {Out.ar(0, SinOsc.ar!2*0.1)}).play

c.write("/Users/tomerbaruch/Desktop/temp.aif")
