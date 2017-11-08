(
SynthDef(\isPitched, {|inBus=0, trig=0|
	var in = SoundIn.ar(inBus);
	var pitch, isPitch;
	var pitchCount=0;
	var fbNode = FbNode(1, 1);
	pitchCount = fbNode.delay(0.1);
	# pitch, isPitch = Pitch.kr(in);
	pitchCount = pitchCount + ((isPitch - 0.5)*0.1);
	//pitchCount.poll;
	SendReply
	fbNode.write(pitchCount);

}).add;
)

Synth(\isPitched)