~path
~defaultsounds=(~path++"feedme-sounds/*").pathMatch.collect({|file| Buffer.read(s, file)});

~defaultsounds[2].play

c=Buffer.alloc(s, s.sampleRate*60*5, 2);
a=[1,4,34,534,4];
Buffer
(
var pos=0;
while {pos<c.numFrames} {
	var buf = ~defaultsounds.choose;
	buf.copyData(c, pos, 0);
	pos = pos + buf.numFrames;
	pos.postln;
};
)

c.plot
c.play