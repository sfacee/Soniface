(
// Make sure that in your system preferences the audio input and output is set to the external interface.
// Then put your cursor somewhere here and press Cmd+Enter
// Then go to system preferences and change audio output to the headphones out and physically plug headphones out to the first two inputs of your interface.
//s.useMotu;
s.useJack;
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
	"initializing".value;
	~initialize.value;
	s.sync(c);
	3.wait;
	"loading synthdefs".postln;
	~loadSynthDefs.value;
	s.sync(c);
	3.wait;
	"setting tables".postln;
	~setTables.value;
	s.sync(c);
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
Ndef(\playIn).clear
Ndef(\playIn).play
Ndef(\playIn).clear
Ndef.clear
Ndef(\playIn, {Out.ar(0, SinOsc.ar!2*0.1)}).play


