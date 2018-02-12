(
// Make sure that in your system preferences the audio input and output is set to the external interface.
// Then put your cursor somewhere here and press Cmd+Enter
// Then go to system preferences and change audio output to the headphones jack and plug headphones out to the first two inputs of your interface.

{
	var c;
	~path="/Users/tomerbaruch/Music/Projects/Sonifying Facebook/soniface/"; // change this to the current folder of the supercollider app
	(~path++"soniface.scd").loadPaths;
	Server.local.options.numInputBusChannels = 8;
	Server.local.options.numOutputBusChannels = 8;
	"booting server".postln;
	s.bootSync(c);
	5.wait;
	"initializing".value;
	~initialize.value;
	s.sync(c);
	5.wait;
	"loading synthdefs".postln;
	~loadSynthDefs.value;
	s.sync(c);
	5.wait;
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

